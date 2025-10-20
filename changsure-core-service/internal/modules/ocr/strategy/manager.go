package strategy

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"sort"
	"sync"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/provider"
)

type StrategyManager struct {
	strategies       []provider.OCRStrategy
	config           *config.OCRConfig
	cache            provider.CacheManager
	metrics          provider.MetricsCollector
	enableConcurrent bool
	maxConcurrency   int
}

func NewStrategyManager(
	strategies []provider.OCRStrategy,
	cfg *config.OCRConfig,
	cache provider.CacheManager,
	metrics provider.MetricsCollector,
) *StrategyManager {
	// 1) จัดลำดับตาม ExecutionOrder ก่อน ถ้าไม่ระบุให้ใช้ Priority (desc)
	ordered := orderStrategies(strategies, cfg)

	// 2) ค่าการทำงานแบบขนาน
	enableConcurrent := false
	maxConc := 1
	if cfg != nil {
		enableConcurrent = cfg.Performance.EnableConcurrent
		maxConc = cfg.Performance.MaxConcurrency
		if maxConc <= 0 {
			maxConc = 1
		}
		if maxConc > len(ordered) {
			maxConc = len(ordered)
		}
	}

	return &StrategyManager{
		strategies:       ordered,
		config:           cfg,
		cache:            cache,
		metrics:          metrics,
		enableConcurrent: enableConcurrent,
		maxConcurrency:   maxConc,
	}
}

func (m *StrategyManager) Execute(ctx context.Context, imageData []byte, language string) (*ExecutionResult, error) {
	startTime := time.Now()

	// ===== Cache (best result) =====
	if m.config != nil && m.config.Performance.EnableCache && m.cache != nil {
		cacheKey := m.createCacheKey(imageData, "all", language)
		if cached, found := m.cache.Get(cacheKey); found {
			return &ExecutionResult{
				BestResult:      cached,
				StrategyResults: nil,
				TotalTime:       time.Since(startTime),
				CacheHit:        true,
			}, nil
		}
	}

	// ===== เลือก total timeout =====
	totalTimeout := m.config.Performance.TotalTimeout
	if totalTimeout <= 0 && m.config.TimeoutSec > 0 {
		totalTimeout = time.Duration(m.config.TimeoutSec) * time.Second
	}
	execCtx := ctx
	var cancelExec context.CancelFunc
	if totalTimeout > 0 {
		execCtx, cancelExec = context.WithTimeout(ctx, totalTimeout)
		defer cancelExec()
	}

	// ===== Execute =====
	var (
		results []*provider.StrategyResult
		err     error
	)
	if m.enableConcurrent {
		results, err = m.executeConcurrent(execCtx, imageData)
	} else {
		results, err = m.executeSequential(execCtx, imageData)
	}
	if err != nil {
		return nil, err
	}

	best := m.selectBestResult(results)
	execResult := &ExecutionResult{
		BestResult:      nil,
		StrategyResults: results,
		TotalTime:       time.Since(startTime),
		CacheHit:        false,
	}
	if best != nil {
		execResult.BestResult = best.OCRResult
	}

	// ===== Set cache เมื่อสำเร็จ =====
	if m.config.Performance.EnableCache && m.cache != nil && best != nil && best.Success {
		cacheKey := m.createCacheKey(imageData, "all", language)
		m.cache.Set(cacheKey, best.OCRResult, m.config.Performance.CacheTTL)
	}

	return execResult, nil
}

func (m *StrategyManager) executeConcurrent(ctx context.Context, imageData []byte) ([]*provider.StrategyResult, error) {
	var (
		wg          sync.WaitGroup
		resultsChan = make(chan *provider.StrategyResult, len(m.strategies))
		sem         = make(chan struct{}, m.maxConcurrency)
	)

	// per-strategy timeout (0 = ไม่กำหนด)
	strategyTimeout := m.config.Performance.StrategyTimeout

	// เกณฑ์หยุดเร็วจาก config (root/strategies)
	stopEarly, stopThreshold := stopConfig(m.config)

	// จะใช้ cancel เฉพาะกรณีเราสร้าง context ที่มี timeout ให้เอง
	ctxMain := ctx
	var cancelMain context.CancelFunc
	if m.config.Performance.TotalTimeout > 0 && ctxMain.Err() == nil {
		ctxMain, cancelMain = context.WithTimeout(ctx, m.config.Performance.TotalTimeout)
		defer cancelMain()
	}

	for _, s := range m.strategies {
		wg.Add(1)
		go func(strat provider.OCRStrategy) {
			defer wg.Done()

			select {
			case sem <- struct{}{}:
				defer func() { <-sem }()
			case <-ctxMain.Done():
				return
			}

			// สร้าง context ของกลยุทธ์
			stratCtx := ctxMain
			var cancelStrat context.CancelFunc
			if strategyTimeout > 0 {
				stratCtx, cancelStrat = context.WithTimeout(ctxMain, strategyTimeout)
				defer cancelStrat()
			}

			res, err := strat.Execute(stratCtx, imageData)
			if err != nil {
				res = &provider.StrategyResult{
					Name:    strat.Name(),
					Success: false,
					Error:   err,
				}
			}

			// บันทึก metrics (ถ้ามี)
			if m.metrics != nil {
				m.metrics.RecordStrategyExecution(strat.Name(), res.ProcessingTime, res.Success)
				if res.Success && res.OCRResult != nil {
					m.metrics.RecordOCRConfidence(strat.Name(), res.OCRResult.Confidence)
				}
				if !res.Success && res.Error != nil {
					m.metrics.RecordError(strat.Name(), res.Error.Error())
				}
			}

			// ส่งผลลัพธ์ออก
			select {
			case resultsChan <- res:
			case <-ctxMain.Done():
				return
			}

			// Stop on first success ตามเกณฑ์ (.env)
			if stopEarly && res.Success && res.OCRResult != nil && res.OCRResult.Confidence >= stopThreshold {
				if cancelMain != nil {
					cancelMain()
				}
			}
		}(s)
	}

	go func() {
		wg.Wait()
		close(resultsChan)
	}()

	results := make([]*provider.StrategyResult, 0, len(m.strategies))
	for r := range resultsChan {
		results = append(results, r)
	}

	if len(results) == 0 {
		return nil, fmt.Errorf("no strategies completed")
	}
	return results, nil
}

func (m *StrategyManager) executeSequential(ctx context.Context, imageData []byte) ([]*provider.StrategyResult, error) {
	results := make([]*provider.StrategyResult, 0, len(m.strategies))

	// per-strategy timeout
	strategyTimeout := m.config.Performance.StrategyTimeout
	stopEarly, stopThreshold := stopConfig(m.config)

	for _, s := range m.strategies {
		// เช็ค cancel / deadline ก่อน
		select {
		case <-ctx.Done():
			return results, ctx.Err()
		default:
		}

		// ทำงานแต่ละกลยุทธ์
		stratCtx := ctx
		var cancelStrat context.CancelFunc
		if strategyTimeout > 0 {
			stratCtx, cancelStrat = context.WithTimeout(ctx, strategyTimeout)
		}
		res, err := s.Execute(stratCtx, imageData)
		if cancelStrat != nil {
			cancelStrat()
		}
		if err != nil {
			res = &provider.StrategyResult{
				Name:    s.Name(),
				Success: false,
				Error:   err,
			}
		}

		// metrics
		if m.metrics != nil {
			m.metrics.RecordStrategyExecution(s.Name(), res.ProcessingTime, res.Success)
			if res.Success && res.OCRResult != nil {
				m.metrics.RecordOCRConfidence(s.Name(), res.OCRResult.Confidence)
			}
			if !res.Success && res.Error != nil {
				m.metrics.RecordError(s.Name(), res.Error.Error())
			}
		}

		results = append(results, res)

		// หยุดเร็วถ้าถึงเกณฑ์
		if stopEarly && res.Success && res.OCRResult != nil && res.OCRResult.Confidence >= stopThreshold {
			break
		}
	}

	if len(results) == 0 {
		return nil, fmt.Errorf("no strategies completed")
	}
	return results, nil
}

func (m *StrategyManager) selectBestResult(results []*provider.StrategyResult) *provider.StrategyResult {
	if len(results) == 0 {
		return nil
	}

	var best *provider.StrategyResult
	bestScore := -1.0

	for _, r := range results {
		if r == nil || r.OCRResult == nil {
			continue
		}
		score := r.OCRResult.Confidence

		// ชอบผลจาก "cropped" เล็กน้อยเพราะมีโอกาสเป็น ID ROI
		if r.Name == "cropped" {
			score *= 1.1
		}

		// ถ้า success ให้บวก bias เล็กน้อย
		if r.Success {
			score += 0.01
		}

		if score > bestScore {
			bestScore = score
			best = r
		}
	}

	// หากไม่มีสักตัวที่มี OCRResult ให้คืนตัวแรก (ตามเดิม)
	if best == nil {
		return results[0]
	}
	return best
}

func (m *StrategyManager) createCacheKey(imageData []byte, strategy string, language string) *provider.CacheKey {
	hash := sha256.Sum256(imageData)
	return &provider.CacheKey{
		ImageHash: hex.EncodeToString(hash[:]),
		Strategy:  strategy,
		Language:  language,
	}
}

// ===== helpers =====

func orderStrategies(strats []provider.OCRStrategy, cfg *config.OCRConfig) []provider.OCRStrategy {
	if cfg == nil || len(cfg.Strategies.ExecutionOrder) == 0 {
		// ไม่มีการกำหนดลำดับ: ใช้ Priority จากกลยุทธ์ (desc)
		out := make([]provider.OCRStrategy, len(strats))
		copy(out, strats)
		sort.Slice(out, func(i, j int) bool {
			return out[i].Priority() > out[j].Priority()
		})
		return out
	}

	// มี ExecutionOrder: จัดเรียงตาม order แล้วค่อยเติมตัวที่เหลือ
	order := cfg.Strategies.ExecutionOrder
	index := make(map[string]provider.OCRStrategy, len(strats))
	for _, s := range strats {
		index[s.Name()] = s
	}

	out := make([]provider.OCRStrategy, 0, len(strats))
	used := make(map[string]bool, len(strats))
	for _, key := range order {
		if s, ok := index[key]; ok {
			out = append(out, s)
			used[key] = true
		}
	}
	for _, s := range strats {
		if !used[s.Name()] {
			out = append(out, s)
		}
	}
	return out
}

func stopConfig(cfg *config.OCRConfig) (stop bool, threshold float64) {
	if cfg == nil {
		return false, 0.80
	}
	stop = cfg.Strategies.StopOnFirstSuccess || cfg.StopOnSuccess
	threshold = 0.80
	if cfg.Strategies.MinConfidenceToStop > 0 {
		threshold = cfg.Strategies.MinConfidenceToStop
	} else if cfg.MinConfidenceStop > 0 {
		threshold = cfg.MinConfidenceStop
	}
	return
}

type ExecutionResult struct {
	BestResult      *provider.OCRResult
	StrategyResults []*provider.StrategyResult
	TotalTime       time.Duration
	CacheHit        bool
}
