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

	lang := "eng"
	oem := 1 // ✅ ใช้ LSTM only
	psmDefault := 7
	upscale := 3.0 // ✅ เพิ่มจาก 2.0
	stopOnSuccess := true
	minConfidenceStop := 0.75 // ✅ ลดจาก 0.80
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
		if s.upscaleFactor > 0 {
			upscale = s.upscaleFactor
		} else if s.cfg.IDCard.UpscaleFactor > 0 {
			upscale = s.cfg.IDCard.UpscaleFactor
		}

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

		if s.cfg.Performance.StrategyTimeout > 0 {
			strategyTimeout = s.cfg.Performance.StrategyTimeout
		}
	}

	// ✅ เพิ่มความหลากหลายของ regions มากขึ้น
	var regions []*provider.Region
	if s.cfg != nil && s.cfg.IDCard.IDNumberRegion.Enabled {
		base := s.cfg.IDCard.IDNumberRegion
		
		// Base + 8 variants (เพิ่มจาก 5 เดิม)
		regions = append(regions,
			&provider.Region{X: base.X, Y: base.Y, Width: base.Width, Height: base.Height, Type: "base"},
			
			// Horizontal shifts
			&provider.Region{X: clamp01(base.X - 0.05), Y: base.Y, Width: base.Width, Height: base.Height, Type: "shift_left_far"},
			&provider.Region{X: clamp01(base.X - 0.03), Y: base.Y, Width: base.Width, Height: base.Height, Type: "shift_left"},
			&provider.Region{X: clamp01(base.X + 0.03), Y: base.Y, Width: base.Width, Height: base.Height, Type: "shift_right"},
			&provider.Region{X: clamp01(base.X + 0.05), Y: base.Y, Width: base.Width, Height: base.Height, Type: "shift_right_far"},
			
			// Vertical shifts
			&provider.Region{X: base.X, Y: clamp01(base.Y - 0.03), Width: base.Width, Height: base.Height, Type: "shift_up"},
			&provider.Region{X: base.X, Y: clamp01(base.Y + 0.03), Width: base.Width, Height: base.Height, Type: "shift_down"},
			
			// Size variants
			&provider.Region{X: clamp01(base.X - 0.05), Y: clamp01(base.Y - 0.01), Width: clamp01(base.Width + 0.10), Height: clamp01(base.Height + 0.02), Type: "wider_taller"},
			&provider.Region{X: clamp01(base.X + 0.02), Y: clamp01(base.Y + 0.01), Width: clamp01(base.Width - 0.04), Height: clamp01(base.Height - 0.01), Type: "tighter"},
		)
	} else {
		regions = []*provider.Region{
			{X: 0.20, Y: 0.12, Width: 0.60, Height: 0.10, Type: "standard"},
			{X: 0.15, Y: 0.10, Width: 0.70, Height: 0.12, Type: "wider"},
			{X: 0.25, Y: 0.14, Width: 0.50, Height: 0.08, Type: "center"},
		}
	}

	if s.regionDetector != nil {
		if auto, err := s.regionDetector.DetectIDNumberRegion(ctx, imageData); err == nil && auto != nil {
			auto.Type = "auto_detect"
			regions = append(regions, auto)
		}
	}

	// ✅ เพิ่ม PSM variants มากขึ้น
	psmModes := uniqueInts([]int{
		psmDefault, // ค่าจาก config
		7,  // Single line
		6,  // Uniform block
		13, // Raw line
		11, // Sparse text
		8,  // Single word
	})

	var best *provider.StrategyResult

	if strategyTimeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, strategyTimeout)
		defer cancel()
	}

	for _, region := range regions {
		select {
		case <-ctx.Done():
			if best != nil {
				return best, nil
			}
			return &provider.StrategyResult{
				Name:           s.Name(),
				Success:        false,
				Error:          ctx.Err(),
				ProcessingTime: time.Since(startTime),
			}, nil
		default:
		}

		croppedData, err := s.regionDetector.CropRegion(ctx, imageData, region)
		if err != nil {
			continue
		}

		grayData, err := s.imageProcessor.ConvertToGrayscale(ctx, croppedData)
		if err != nil {
			grayData = croppedData
		}

		upscaledData, err := s.imageProcessor.Upscale(ctx, grayData, upscale)
		if err != nil {
			upscaledData = grayData
		}

		enhancedData, err := s.imageProcessor.EnhanceContrast(ctx, upscaledData)
		if err != nil {
			enhancedData = upscaledData
		}

		normalizedData, err := s.imageProcessor.Normalize(ctx, enhancedData)
		if err != nil {
			normalizedData = enhancedData
		}

		for _, psm := range psmModes {
			result, err := s.ocrProvider.ExtractText(ctx, normalizedData, &provider.OCROptions{
				Language: lang,
				PSM:      psm,
				OEM:      oem,
			})
			if err != nil || result == nil {
				continue
			}

			// ✅ ใช้ validator ที่ปรับปรุงแล้ว
			idNumber, idErr := s.validator.ExtractIDNumber(result.Text)
			if idErr == nil && idNumber != "" {
				candidate := &provider.StrategyResult{
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

				// Early exit ถ้าถึงเกณฑ์
				if stopOnSuccess && result.Confidence >= minConfidenceStop {
					return candidate, nil
				}

				// เก็บ best
				if best == nil || result.Confidence > best.OCRResult.Confidence {
					best = candidate
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
		Error:          fmt.Errorf("no valid ID found after trying %d regions and %d PSM modes", len(regions), len(psmModes)),
		ProcessingTime: time.Since(startTime),
	}, nil
}

func clamp01(v float64) float64 {
	if v < 0 {
		return 0
	}
	if v > 1 {
		return 1
	}
	return v
}

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