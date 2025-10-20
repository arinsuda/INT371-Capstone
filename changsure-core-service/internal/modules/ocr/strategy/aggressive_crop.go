package strategy

import (
	"fmt"
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type AggressiveCropStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	regionDetector provider.RegionDetector
	validator      *validator.IDCardValidator
	upscaleFactor  float64
	priority       int
}

func NewAggressiveCropStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	detector provider.RegionDetector,
	validator *validator.IDCardValidator,
	upscaleFactor float64,
) *AggressiveCropStrategy {
	return &AggressiveCropStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		regionDetector: detector,
		validator:      validator,
		upscaleFactor:  upscaleFactor,
		priority:       110,
	}
}

func (s *AggressiveCropStrategy) Name() string {
	return "aggressive_crop"
}

func (s *AggressiveCropStrategy) Priority() int {
	return s.priority
}

func (s *AggressiveCropStrategy) ShouldRetry() bool {
	return true
}

func (s *AggressiveCropStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	startTime := time.Now()

	regions := []*provider.Region{
		{X: 0.20, Y: 0.12, Width: 0.60, Height: 0.10, Type: "standard"},
		{X: 0.15, Y: 0.10, Width: 0.70, Height: 0.12, Type: "wider"},
		{X: 0.25, Y: 0.14, Width: 0.50, Height: 0.08, Type: "center"},
	}

	var bestResult *provider.StrategyResult

	for _, region := range regions {
		croppedData, err := s.regionDetector.CropRegion(ctx, imageData, region)
		if err != nil {
			continue
		}

		grayData, err := s.imageProcessor.ConvertToGrayscale(ctx, croppedData)
		if err != nil {
			grayData = croppedData
		}

		upscaledData, err := s.imageProcessor.Upscale(ctx, grayData, s.upscaleFactor)
		if err != nil {
			continue
		}

		enhancedData, err := s.imageProcessor.EnhanceContrast(ctx, upscaledData)
		if err != nil {
			enhancedData = upscaledData
		}

		normalizedData, err := s.imageProcessor.Normalize(ctx, enhancedData)
		if err != nil {
			normalizedData = enhancedData
		}

		psmModes := []int{7, 6, 11, 13}

		for _, psm := range psmModes {
			result, err := s.ocrProvider.ExtractText(ctx, normalizedData, &provider.OCROptions{
				Language: "eng",
				PSM:      psm,
				OEM:      3,
			})

			if err != nil || result == nil {
				continue
			}

			idNumber, idErr := s.validator.ExtractIDNumber(result.Text)
			if idErr == nil && idNumber != "" {
				bestResult = &provider.StrategyResult{
					Name:           s.Name(),
					Success:        true,
					OCRResult:      result,
					ProcessingTime: time.Since(startTime),
					Metadata: map[string]interface{}{
						"id_found":       true,
						"id_number":      idNumber,
						"region":         region.Type,
						"psm":            psm,
						"upscale_factor": s.upscaleFactor,
					},
				}
				break
			}
		}

		if bestResult != nil && bestResult.Success {
			break
		}
	}

	if bestResult != nil && bestResult.Success {
		return bestResult, nil
	}

	return &provider.StrategyResult{
		Name:           s.Name(),
		Success:        false,
		Error:          fmt.Errorf("no valid ID found after trying all regions and PSM modes"),
		ProcessingTime: time.Since(startTime),
	}, nil
}
