package strategy

import (
	"context"
	"fmt"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type CroppedRegionStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	regionDetector provider.RegionDetector
	validator      *validator.IDCardValidator
	cfg            *config.OCRConfig

	priority int
}

func NewCroppedRegionStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	detector provider.RegionDetector,
	validator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) *CroppedRegionStrategy {
	return &CroppedRegionStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		regionDetector: detector,
		validator:      validator,
		cfg:            cfg,
		priority:       100, // StrategyManager จะจัดลำดับจริงตาม ExecutionOrder
	}
}

func (s *CroppedRegionStrategy) Name() string      { return "cropped" }
func (s *CroppedRegionStrategy) Priority() int     { return s.priority }
func (s *CroppedRegionStrategy) ShouldRetry() bool { return true }

func (s *CroppedRegionStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	start := time.Now()

	// ===== ค่าจาก config / .env =====
	lang := "eng"
	psm := 6
	oem := 3
	upscale := 1.0
	doNormalize := true
	stopOnSuccess := false
	minConfidenceStop := 0.80

	if s.cfg != nil {
		if s.cfg.Language != "" {
			lang = s.cfg.Language
		}
		if s.cfg.IDCard.PSM > 0 {
			psm = s.cfg.IDCard.PSM
		} else if s.cfg.PSM > 0 {
			psm = s.cfg.PSM
		}
		if s.cfg.OEM > 0 {
			oem = s.cfg.OEM
		}
		if s.cfg.IDCard.UpscaleFactor > 0 {
			upscale = s.cfg.IDCard.UpscaleFactor
		}
		doNormalize = s.cfg.IDCard.EnableNormalize

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

	// ===== 1) เลือก region =====
	var region *provider.Region
	var err error

	// ถ้าเปิดใช้ region จาก .env ให้ใช้ก่อน
	if s.cfg != nil && s.cfg.IDCard.IDNumberRegion.Enabled {
		r := s.cfg.IDCard.IDNumberRegion
		region = &provider.Region{X: r.X, Y: r.Y, Width: r.Width, Height: r.Height, Type: "env"}
	} else {
		// ไม่เปิด — ให้ detector หา
		region, err = s.regionDetector.DetectIDNumberRegion(ctx, imageData)
		if err != nil || region == nil {
			return &provider.StrategyResult{
				Name:           s.Name(),
				Success:        false,
				Error:          fmt.Errorf("detect id region failed: %w", err),
				ProcessingTime: time.Since(start),
			}, nil
		}
	}

	// ===== 2) Crop =====
	croppedData, err := s.regionDetector.CropRegion(ctx, imageData, region)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          fmt.Errorf("crop failed: %w", err),
			ProcessingTime: time.Since(start),
		}, nil
	}

	// ===== 3) Preprocess (เบาและเร็วสำหรับ ROI) =====
	processed := croppedData

	// Grayscale ช่วย OCR แทบทุกกรณี
	if g, err := s.imageProcessor.ConvertToGrayscale(ctx, processed); err == nil {
		processed = g
	}

	// Upscale ถ้าตั้งไว้ (>1)
	if upscale > 1.0 {
		if u, err := s.imageProcessor.Upscale(ctx, processed, upscale); err == nil {
			processed = u
		}
	}

	// Contrast + Normalize ตาม .env
	if e, err := s.imageProcessor.EnhanceContrast(ctx, processed); err == nil {
		processed = e
	}
	if doNormalize {
		if n, err := s.imageProcessor.Normalize(ctx, processed); err == nil {
			processed = n
		}
	}

	// ===== 4) OCR: ลองหลาย PSM โดยยึดค่า .env เป็นตัวตั้ง =====
	psmModes := uniqueInts([]int{psm, 7, 13, 6}) // 7=line, 13=raw line
	var best *provider.OCRResult
	var bestPSM int
	var lastErr error

	for _, try := range psmModes {
		res, err := s.ocrProvider.ExtractText(ctx, processed, &provider.OCROptions{
			Language: lang,
			PSM:      try,
			OEM:      oem,
		})
		if err != nil || res == nil {
			lastErr = err
			continue
		}

		// ensure Metadata map
		if res.Metadata == nil {
			res.Metadata = make(map[string]interface{}, 4)
		}
		res.Metadata["psm_used"] = try
		res.Metadata["language"] = lang
		res.Metadata["oem"] = oem

		id, idErr := s.validator.ExtractIDNumber(res.Text)
		hasID := idErr == nil && id != ""

		// เกณฑ์หยุดเร็ว
		if stopOnSuccess && hasID && res.Confidence >= minConfidenceStop {
			return &provider.StrategyResult{
				Name:           s.Name(),
				Success:        true,
				OCRResult:      res,
				ProcessingTime: time.Since(start),
				Metadata: map[string]interface{}{
					"id_found":       true,
					"id_number":      id,
					"region":         region,
					"upscale_factor": upscale,
				},
			}, nil
		}

		// เลือก best ตามความเชื่อมั่น/ความยาวข้อความ
		if best == nil ||
			(res.Confidence > best.Confidence) ||
			(res.Confidence == best.Confidence && len(res.Text) > len(best.Text)) {
			best = res
			bestPSM = try
		}
	}

	// ไม่ได้ผลลัพธ์
	if best == nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          fmt.Errorf("ocr failed with all psm modes: %v", lastErr),
			ProcessingTime: time.Since(start),
		}, nil
	}

	// ตรวจ ID อีกรอบที่ผล best
	id, idErr := s.validator.ExtractIDNumber(best.Text)
	hasID := idErr == nil && id != ""

	// ensure Metadata map ก่อนใส่เพิ่ม
	if best.Metadata == nil {
		best.Metadata = make(map[string]interface{}, 6)
	}
	best.Metadata["psm_used"] = bestPSM
	best.Metadata["raw_text_len"] = len(best.Text)

	return &provider.StrategyResult{
		Name:           s.Name(),
		Success:        hasID || best.Text != "",
		OCRResult:      best,
		ProcessingTime: time.Since(start),
		Metadata: map[string]interface{}{
			"id_found":       hasID,
			"id_number":      id,
			"region":         region,
			"upscale_factor": upscale,
		},
	}, nil
}