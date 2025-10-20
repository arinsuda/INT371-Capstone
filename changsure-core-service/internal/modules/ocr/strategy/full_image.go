package strategy

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type FullImageStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	validator      *validator.IDCardValidator
	cfg            *config.OCRConfig

	priority int
}

func NewFullImageStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	validator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) *FullImageStrategy {
	return &FullImageStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		validator:      validator,
		cfg:            cfg,
		priority:       50, // ลำดับจริงปล่อยให้ StrategyManager/ExecutionOrder จัดการ
	}
}

func (s *FullImageStrategy) Name() string      { return "full" }
func (s *FullImageStrategy) Priority() int     { return s.priority }
func (s *FullImageStrategy) ShouldRetry() bool { return true }

func (s *FullImageStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	start := time.Now()

	// ===== ค่าจาก config / .env =====
	lang := "eng"
	psm := 6
	oem := 3
	doNormalize := true
	stopOnSuccess := false
	minConfidenceStop := 0.80

	if s.cfg != nil {
		if s.cfg.Language != "" {
			lang = s.cfg.Language
		}
		// PSM: ให้ IDCard.PSM ชนะ PSM root ถ้าตั้ง
		if s.cfg.IDCard.PSM > 0 {
			psm = s.cfg.IDCard.PSM
		} else if s.cfg.PSM > 0 {
			psm = s.cfg.PSM
		}
		if s.cfg.OEM > 0 {
			oem = s.cfg.OEM
		}

		// Normalize จาก .env (ใช้ flag ของ IDCard เป็นค่าเริ่ม เนื่องจากไม่มี global normalize)
		doNormalize = s.cfg.IDCard.EnableNormalize

		// Stop-on-success + เกณฑ์หยุด
		stopOnSuccess = s.cfg.StopOnSuccess || s.cfg.Strategies.StopOnFirstSuccess
		if s.cfg.MinConfidenceStop > 0 {
			minConfidenceStop = s.cfg.MinConfidenceStop
		}
		if s.cfg.Strategies.MinConfidenceToStop > 0 {
			minConfidenceStop = s.cfg.Strategies.MinConfidenceToStop
		}

		// Strategy-level timeout
		if s.cfg.Performance.StrategyTimeout > 0 {
			var cancel context.CancelFunc
			ctx, cancel = context.WithTimeout(ctx, s.cfg.Performance.StrategyTimeout)
			defer cancel()
		}
	}

	// ===== 1) Preprocess ทั้งภาพ =====
	processed, err := s.imageProcessor.Preprocess(ctx, imageData, &provider.PreprocessOptions{
		Grayscale:       true,        // ช่วย OCR โดยรวม
		Normalize:       doNormalize, // จาก .env
		EnhanceContrast: true,        // เอกสารมักซีด/แสงไม่สม่ำเสมอ
		// Upscale: ปกติไม่ขยายทั้งรูปเพื่อคุมเวลา/เมมโมรี่ (สตราทีจี้อื่นจัดการ ROI แล้ว)
	})
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(start),
		}, nil
	}

	// ===== 2) OCR: ลองหลาย PSM โดยยึดค่าจาก .env เป็นตัวตั้ง =====
	psmCandidates := uniqueInts([]int{psm, 6, 3, 11}) // 6:block, 3:full auto, 11:sparse text
	var best *provider.StrategyResult

	for _, try := range psmCandidates {
		res, err := s.ocrProvider.ExtractText(ctx, processed, &provider.OCROptions{
			Language: lang,
			PSM:      try,
			OEM:      oem,
		})
		if err != nil || res == nil {
			continue
		}

		idNumber, idErr := s.validator.ExtractIDNumber(res.Text)
		hasID := idErr == nil && idNumber != ""

		candidate := &provider.StrategyResult{
			Name:           s.Name(),
			Success:        hasID,
			OCRResult:      res,
			ProcessingTime: time.Since(start),
			Metadata: map[string]interface{}{
				"id_found":  hasID,
				"id_number": idNumber,
				"language":  lang,
				"psm":       try,
				"oem":       oem,
			},
		}

		// หยุดเร็วเมื่อถึงเกณฑ์ที่กำหนด
		if stopOnSuccess && hasID && res.Confidence >= minConfidenceStop {
			return candidate, nil
		}

		// เก็บ best ตามความเชื่อมั่น
		if best == nil || (candidate.OCRResult != nil && best.OCRResult != nil &&
			candidate.OCRResult.Confidence > best.OCRResult.Confidence) {
			best = candidate
		}
	}

	// ถ้าไม่มี candidate เลย
	if best == nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			ProcessingTime: time.Since(start),
		}, nil
	}

	return best, nil
}