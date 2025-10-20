package strategy

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type AutoRotateStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	validator      *validator.IDCardValidator
	cfg            *config.OCRConfig

	priority int
}

func NewAutoRotateStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	validator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) *AutoRotateStrategy {
	return &AutoRotateStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		validator:      validator,
		cfg:            cfg,
		priority:       70, // ใช้เลขคงที่; ลำดับจริงปล่อยให้ StrategyManager จัดตาม ExecutionOrder
	}
}

func (s *AutoRotateStrategy) Name() string      { return "auto_rotate" }
func (s *AutoRotateStrategy) Priority() int     { return s.priority }
func (s *AutoRotateStrategy) ShouldRetry() bool { return false }

func (s *AutoRotateStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	start := time.Now()

	// ===== ค่าจาก config / .env =====
	lang := "eng"
	if s.cfg != nil && s.cfg.Language != "" {
		lang = s.cfg.Language
	}

	// PSM/OEM: ให้ใช้ IDCard.PSM > PSM (root) เป็นลำดับ
	psm := 6
	oem := 3
	if s.cfg != nil {
		if s.cfg.IDCard.PSM > 0 {
			psm = s.cfg.IDCard.PSM
		} else if s.cfg.PSM > 0 {
			psm = s.cfg.PSM
		}
		if s.cfg.OEM > 0 {
			oem = s.cfg.OEM
		}
	}

	// Preprocess flags
	doNormalize := true
	if s.cfg != nil {
		doNormalize = s.cfg.IDCard.EnableNormalize
	}

	// Stop on success & threshold (จะคืนผลเร็วถ้าเชื่อมั่นถึงเกณฑ์)
	stopOnSuccess := false
	minConfidenceStop := 0.80
	if s.cfg != nil {
		stopOnSuccess = s.cfg.StopOnSuccess || s.cfg.Strategies.StopOnFirstSuccess
		if s.cfg.MinConfidenceStop > 0 {
			minConfidenceStop = s.cfg.MinConfidenceStop
		}
		if s.cfg.Strategies.MinConfidenceToStop > 0 {
			minConfidenceStop = s.cfg.Strategies.MinConfidenceToStop
		}
	}

	// Strategy-level timeout
	if s.cfg != nil && s.cfg.Performance.StrategyTimeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, s.cfg.Performance.StrategyTimeout)
		defer cancel()
	}

	// ===== 1) Auto rotate =====
	rotatedData, angle, err := s.imageProcessor.AutoRotate(ctx, imageData)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(start),
		}, nil
	}

	// ===== 2) Preprocess ตาม config =====
	processedData, err := s.imageProcessor.Preprocess(ctx, rotatedData, &provider.PreprocessOptions{
		Grayscale:       true,        // ช่วย OCR เสมอ
		Normalize:       doNormalize, // จาก .env
		EnhanceContrast: true,        // เอกสารมักซีด/แสงไม่สม่ำเสมอ
		// Upscale ไม่จำเป็นในขั้นตอนนี้เพราะ auto-rotate โฟกัส orientation
	})
	if err != nil {
		processedData = rotatedData
	}

	// ===== 3) OCR (ลอง PSM เล็กน้อย โดยยึดค่าจาก .env เป็นตัวตั้ง) =====
	psmCandidates := []int{psm, 6, 7}
	var best *provider.StrategyResult

	for _, tryPSM := range uniqueInts(psmCandidates) {
		res, err := s.ocrProvider.ExtractText(ctx, processedData, &provider.OCROptions{
			Language: lang,
			PSM:      tryPSM,
			OEM:      oem,
		})
		if err != nil || res == nil {
			continue
		}

		idNumber, idErr := s.validator.ExtractIDNumber(res.Text)
		hasValidID := idErr == nil && idNumber != ""

		candidate := &provider.StrategyResult{
			Name:           s.Name(),
			Success:        hasValidID,
			OCRResult:      res,
			ProcessingTime: time.Since(start),
			Metadata: map[string]interface{}{
				"id_found":       hasValidID,
				"id_number":      idNumber,
				"rotation_angle": angle,
				"language":       lang,
				"psm":            tryPSM,
				"oem":            oem,
			},
		}

		// เก็บ best ตาม confidence
		if best == nil || (candidate.OCRResult != nil && best.OCRResult != nil &&
			candidate.OCRResult.Confidence > best.OCRResult.Confidence) {
			best = candidate
		}

		// หยุดเร็วเมื่อถึงเกณฑ์
		if stopOnSuccess && hasValidID && res.Confidence >= minConfidenceStop {
			return candidate, nil
		}
	}

	// ถ้าไม่มีข้อความที่เป็น ID แต่ OCR ได้ ให้คืน best (success=false)
	if best != nil {
		return best, nil
	}

	// ไม่ได้อะไรเลย
	return &provider.StrategyResult{
		Name:           s.Name(),
		Success:        false,
		ProcessingTime: time.Since(start),
	}, nil
}

// ===== helpers =====

func uniqueInts(xs []int) []int {
	seen := make(map[int]struct{}, len(xs))
	out := make([]int, 0, len(xs))
	for _, v := range xs {
		if _, ok := seen[v]; !ok {
			seen[v] = struct{}{}
			out = append(out, v)
		}
	}
	return out
}
