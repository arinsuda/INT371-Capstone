package strategy

import (
	"context"
	"fmt"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type AggressiveCropStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	regionDetector provider.RegionDetector
	validator      *validator.IDCardValidator

	cfg           *config.OCRConfig
	upscaleFactor float64
	priority      int
}

func NewAggressiveCropStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	detector provider.RegionDetector,
	validator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) *AggressiveCropStrategy {
	p := 110

	if cfg != nil && len(cfg.Strategies.ExecutionOrder) > 0 {
		for idx, name := range cfg.Strategies.ExecutionOrder {
			if name == "aggressive_crop" {
				p = idx + 1
				break
			}
		}
	}

	return &AggressiveCropStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		regionDetector: detector,
		validator:      validator,
		cfg:            cfg,
		upscaleFactor:  0,
		priority:       p,
	}
}

func (s *AggressiveCropStrategy) Name() string      { return "aggressive_crop" }
func (s *AggressiveCropStrategy) Priority() int     { return s.priority }
func (s *AggressiveCropStrategy) ShouldRetry() bool { return true }

func (s *AggressiveCropStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	startTime := time.Now()

	// ============ โหลดค่าที่มีผลจาก config ============
	lang := "eng"
	oem := 3
	psmDefault := 7
	upscale := 2.0
	stopOnSuccess := true
	minConfidenceStop := 0.80
	strategyTimeout := time.Duration(0)

	if s.cfg != nil {
		if s.cfg.Language != "" {
			lang = s.cfg.Language
		}
		if s.cfg.OEM > 0 {
			oem = s.cfg.OEM
		}
		if s.cfg.IDCard.PSM > 0 {
			psmDefault = s.cfg.IDCard.PSM
		} else if s.cfg.PSM > 0 {
			psmDefault = s.cfg.PSM
		}
		// upscaleFactor: ให้ใช้ field ใน struct ถ้าตั้งมา ไม่งั้นใช้จาก cfg
		if s.upscaleFactor > 0 {
			upscale = s.upscaleFactor
		} else if s.cfg.IDCard.UpscaleFactor > 0 {
			upscale = s.cfg.IDCard.UpscaleFactor
		}

		// stop-on-success + เกณฑ์หยุด
		if s.cfg.StopOnSuccess {
			stopOnSuccess = true
		}
		if s.cfg.Strategies.StopOnFirstSuccess {
			stopOnSuccess = true
		}
		if s.cfg.MinConfidenceStop > 0 {
			minConfidenceStop = s.cfg.MinConfidenceStop
		}
		if s.cfg.Strategies.MinConfidenceToStop > 0 {
			minConfidenceStop = s.cfg.Strategies.MinConfidenceToStop
		}

		// ต่อ strategy timeout ถ้ามี (ใช้ timeouts ที่สั้น เพื่อไม่ลากทั้งชุด)
		if s.cfg.Performance.StrategyTimeout > 0 {
			strategyTimeout = s.cfg.Performance.StrategyTimeout
		}
	}

	// ============ เตรียมชุด region candidates จาก .env ============
	// ใช้ค่าใน .env: OCR_ID_CROP_X/Y/W/H เป็นฐาน แล้วสร้างตัวแปรรอบ ๆ (กว้าง/แคบ/ขยับ)
	var regions []*provider.Region
	if s.cfg != nil && s.cfg.IDCard.IDNumberRegion.Enabled {
		base := s.cfg.IDCard.IDNumberRegion
		// base
		regions = append(regions, &provider.Region{X: base.X, Y: base.Y, Width: base.Width, Height: base.Height, Type: "base"})
		// variants: ขยาย/ย่อ/ขยับเล็กน้อยเพื่อชดเชย misalignment
		regions = append(regions,
			&provider.Region{X: clamp01(base.X - 0.03), Y: clamp01(base.Y - 0.02), Width: clamp01(base.Width + 0.06), Height: clamp01(base.Height + 0.02), Type: "wider"},
			&provider.Region{X: clamp01(base.X + 0.03), Y: clamp01(base.Y + 0.02), Width: clamp01(base.Width - 0.04), Height: clamp01(base.Height - 0.01), Type: "tighter"},
			&provider.Region{X: base.X, Y: clamp01(base.Y - 0.02), Width: base.Width, Height: base.Height, Type: "up_shift"},
			&provider.Region{X: base.X, Y: clamp01(base.Y + 0.02), Width: base.Width, Height: base.Height, Type: "down_shift"},
		)
	} else {
		// fallback เดิม
		regions = []*provider.Region{
			{X: 0.20, Y: 0.12, Width: 0.60, Height: 0.10, Type: "standard"},
			{X: 0.15, Y: 0.10, Width: 0.70, Height: 0.12, Type: "wider"},
			{X: 0.25, Y: 0.14, Width: 0.50, Height: 0.08, Type: "center"},
		}
	}

	// ถ้ามี RegionDetector ให้ลอง auto-detect เป็นตัวเลือกท้าย ๆ
	if s.regionDetector != nil {
		if auto, err := s.regionDetector.DetectIDNumberRegion(ctx, imageData); err == nil && auto != nil {
			auto.Type = "auto_detect"
			regions = append(regions, auto)
		}
	}

	// ============ เตรียม PSM modes โดยยึด .env เป็นหลัก ============
	psmModes := uniqueInts([]int{
		psmDefault, // ค่าจาก .env ก่อน
		7, 6, 11, 13,
	})

	var best *provider.StrategyResult

	// Strategy-level timeout (หากตั้งไว้)
	if strategyTimeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, strategyTimeout)
		defer cancel()
	}

	for _, region := range regions {
		// 1) crop
		croppedData, err := s.regionDetector.CropRegion(ctx, imageData, region)
		if err != nil {
			continue
		}
		// 2) grayscale
		grayData, err := s.imageProcessor.ConvertToGrayscale(ctx, croppedData)
		if err != nil {
			grayData = croppedData
		}
		// 3) upscaling (ตาม .env)
		upscaledData, err := s.imageProcessor.Upscale(ctx, grayData, upscale)
		if err != nil {
			upscaledData = grayData
		}
		// 4) contrast
		enhancedData, err := s.imageProcessor.EnhanceContrast(ctx, upscaledData)
		if err != nil {
			enhancedData = upscaledData
		}
		// 5) normalize
		normalizedData, err := s.imageProcessor.Normalize(ctx, enhancedData)
		if err != nil {
			normalizedData = enhancedData
		}

		// 6) ลองหลาย PSM โดยยึด OEM/Language จาก .env
		for _, psm := range psmModes {
			result, err := s.ocrProvider.ExtractText(ctx, normalizedData, &provider.OCROptions{
				Language: lang,
				PSM:      psm,
				OEM:      oem,
			})
			if err != nil || result == nil {
				continue
			}

			// ถ้าพบรหัส 13 หลัก ถือว่า success
			idNumber, idErr := s.validator.ExtractIDNumber(result.Text)
			if idErr == nil && idNumber != "" {
				best = &provider.StrategyResult{
					Name:           s.Name(),
					Success:        true,
					OCRResult:      result,
					ProcessingTime: time.Since(startTime),
					Metadata: map[string]interface{}{
						"id_found":       true,
						"id_number":      idNumber,
						"region":         region.Type,
						"psm":            psm,
						"oem":            oem,
						"language":       lang,
						"upscale_factor": upscale,
					},
				}
				// stop-on-success (จาก .env)
				if stopOnSuccess && result.Confidence >= minConfidenceStop {
					return best, nil
				}
				// ไม่งั้นเก็บไว้ แต่ยังลองต่อเพื่อหา confidence ที่ดีกว่า
				if best == nil || result.Confidence > best.OCRResult.Confidence {
					// (จริง ๆ ไม่เข้าเคสนี้เพราะเพิ่งกำหนด best)
				}
			}
		}
	}

	if best != nil && best.Success {
		return best, nil
	}

	return &provider.StrategyResult{
		Name:           s.Name(),
		Success:        false,
		Error:          fmt.Errorf("no valid ID found after trying all regions and PSM modes"),
		ProcessingTime: time.Since(startTime),
	}, nil
}

// ===== helpers =====

func clamp01(v float64) float64 {
	if v < 0 {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

