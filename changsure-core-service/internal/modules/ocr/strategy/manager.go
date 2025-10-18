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

// StrategyManager จัดการการรัน strategies
type StrategyManager struct {
	strategies       []provider.OCRStrategy
	config           *config.OCRConfig
	cache            provider.CacheManager
	metrics          provider.MetricsCollector
	enableConcurrent bool
}

func NewStrategyManager(
	strategies []provider.OCRStrategy,
	cfg *config.OCRConfig,
	cache provider.CacheManager,
	metrics provider.MetricsCollector,
) *StrategyManager {
	// เรียงตาม priority
	sort.Slice(strategies, func(i, j int) bool {
		return strategies[i].Priority() > strategies[j].Priority()
	})

	return &StrategyManager{
		strategies:       strategies,
		config:           cfg,
		cache:            cache,
		metrics:          metrics,
		enableConcurrent: cfg.Performance.EnableConcurrent,
	}
}

// Execute รัน strategies ตาม configuration
func (m *StrategyManager) Execute(ctx context.Context, imageData []byte, language string) (*ExecutionResult, error) {
	startTime := time.Now()

	// เช็ค cache ก่อน
	if m.config.Performance.EnableCache && m.cache != nil {
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

	var results []*provider.StrategyResult
	var err error

	if m.enableConcurrent {
		results, err = m.executeConcurrent(ctx, imageData)
	} else {
		results, err = m.executeSequential(ctx, imageData)
	}

	if err != nil {
		return nil, err
	}

	// เลือก result ที่ดีที่สุด
	bestResult := m.selectBestResult(results)

	executionResult := &ExecutionResult{
		BestResult:      bestResult.OCRResult,
		StrategyResults: results,
		TotalTime:       time.Since(startTime),
		CacheHit:        false,
	}

	// บันทึกลง cache
	if m.config.Performance.EnableCache && m.cache != nil && bestResult.Success {
		cacheKey := m.createCacheKey(imageData, "all", language)
		m.cache.Set(cacheKey, bestResult.OCRResult, m.config.Performance.CacheTTL)
	}

	return executionResult, nil
}

// executeConcurrent รัน strategies แบบ concurrent
func (m *StrategyManager) executeConcurrent(ctx context.Context, imageData []byte) ([]*provider.StrategyResult, error) {
	var wg sync.WaitGroup
	resultsChan := make(chan *provider.StrategyResult, len(m.strategies))
	semaphore := make(chan struct{}, m.config.Performance.MaxConcurrency)

	// สร้าง context ที่มี timeout
	execCtx, cancel := context.WithTimeout(ctx, m.config.Performance.TotalTimeout)
	defer cancel()

	for _, strategy := range m.strategies {
		wg.Add(1)
		go func(s provider.OCRStrategy) {
			defer wg.Done()

			// จำกัดจำนวน concurrent executions
			select {
			case semaphore <- struct{}{}:
				defer func() { <-semaphore }()
			case <-execCtx.Done():
				return
			}

			// รัน strategy พร้อม timeout
			strategyCtx, strategyCancel := context.WithTimeout(execCtx, m.config.Performance.StrategyTimeout)
			defer strategyCancel()

			result, err := s.Execute(strategyCtx, imageData)
			if err != nil {
				result = &provider.StrategyResult{
					Name:    s.Name(),
					Success: false,
					Error:   err,
				}
			}

			// บันทึก metrics
			if m.metrics != nil {
				m.metrics.RecordStrategyExecution(s.Name(), result.ProcessingTime, result.Success)
				if result.Success && result.OCRResult != nil {
					m.metrics.RecordOCRConfidence(s.Name(), result.OCRResult.Confidence)
				}
				if !result.Success && result.Error != nil {
					m.metrics.RecordError(s.Name(), result.Error.Error())
				}
			}

			resultsChan <- result

			// Early stopping ถ้า config เปิดไว้
			if m.config.Strategies.StopOnFirstSuccess && 
			   result.Success && 
			   result.OCRResult != nil && 
			   result.OCRResult.Confidence >= m.config.Strategies.MinConfidenceToStop {
				cancel() // หยุด strategies อื่นที่ยังรันอยู่
			}
		}(strategy)
	}

	// รอให้ทุก goroutine เสร็จ
	go func() {
		wg.Wait()
		close(resultsChan)
	}()

	// รวบรวม results
	var results []*provider.StrategyResult
	for result := range resultsChan {
		results = append(results, result)
	}

	if len(results) == 0 {
		return nil, fmt.Errorf("no strategies completed")
	}

	return results, nil
}

// executeSequential รัน strategies แบบ sequential
func (m *StrategyManager) executeSequential(ctx context.Context, imageData []byte) ([]*provider.StrategyResult, error) {
	var results []*provider.StrategyResult

	// สร้าง context ที่มี timeout
	execCtx, cancel := context.WithTimeout(ctx, m.config.Performance.TotalTimeout)
	defer cancel()

	for _, strategy := range m.strategies {
		// ตรวจสอบว่า context ยัง valid อยู่ไหม
		select {
		case <-execCtx.Done():
			return results, execCtx.Err()
		default:
		}

		// รัน strategy พร้อม timeout
		strategyCtx, strategyCancel := context.WithTimeout(execCtx, m.config.Performance.StrategyTimeout)
		
		result, err := strategy.Execute(strategyCtx, imageData)
		strategyCancel()

		if err != nil {
			result = &provider.StrategyResult{
				Name:    strategy.Name(),
				Success: false,
				Error:   err,
			}
		}

		// บันทึก metrics
		if m.metrics != nil {
			m.metrics.RecordStrategyExecution(strategy.Name(), result.ProcessingTime, result.Success)
			if result.Success && result.OCRResult != nil {
				m.metrics.RecordOCRConfidence(strategy.Name(), result.OCRResult.Confidence)
			}
			if !result.Success && result.Error != nil {
				m.metrics.RecordError(strategy.Name(), result.Error.Error())
			}
		}

		results = append(results, result)

		// Early stopping
		if m.config.Strategies.StopOnFirstSuccess && 
		   result.Success && 
		   result.OCRResult != nil && 
		   result.OCRResult.Confidence >= m.config.Strategies.MinConfidenceToStop {
			break
		}
	}

	if len(results) == 0 {
		return nil, fmt.Errorf("no strategies completed")
	}

	return results, nil
}

// selectBestResult เลือก result ที่ดีที่สุด
func (m *StrategyManager) selectBestResult(results []*provider.StrategyResult) *provider.StrategyResult {
	if len(results) == 0 {
		return nil
	}

	var best *provider.StrategyResult
	bestScore := -1.0

	for _, result := range results {
		if !result.Success || result.OCRResult == nil {
			continue
		}

		// คำนวณคะแนน (confidence * priority weight)
		score := result.OCRResult.Confidence
		
		// เพิ่มคะแนนให้ strategy บางตัว
		if result.Name == "cropped" {
			score *= 1.1 // ให้น้ำหนักมากกว่า
		}

		if score > bestScore {
			bestScore = score
			best = result
		}
	}

	// ถ้าไม่เจอ result ที่ success เลย ส่ง result แรก
	if best == nil {
		return results[0]
	}

	return best
}

// createCacheKey สร้าง cache key
func (m *StrategyManager) createCacheKey(imageData []byte, strategy string, language string) *provider.CacheKey {
	hash := sha256.Sum256(imageData)
	return &provider.CacheKey{
		ImageHash: hex.EncodeToString(hash[:]),
		Strategy:  strategy,
		Language:  language,
	}
}

// ExecutionResult ผลลัพธ์จากการรัน strategies
type ExecutionResult struct {
	BestResult      *provider.OCRResult
	StrategyResults []*provider.StrategyResult
	TotalTime       time.Duration
	CacheHit        bool
}