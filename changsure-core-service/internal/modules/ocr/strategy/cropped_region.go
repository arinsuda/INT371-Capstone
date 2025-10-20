package strategy

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type CroppedRegionStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	regionDetector provider.RegionDetector
	validator      *validator.IDCardValidator
	language       string
	priority       int
	upscaleFactor  float64
}

func NewCroppedRegionStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	detector provider.RegionDetector,
	validator *validator.IDCardValidator,
	language string,
	upscaleFactor float64,
) *CroppedRegionStrategy {
	return &CroppedRegionStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		regionDetector: detector,
		validator:      validator,
		language:       language,
		priority:       100,
		upscaleFactor:  upscaleFactor,
	}
}

func (s *CroppedRegionStrategy) Name() string {
	return "cropped_region"
}

func (s *CroppedRegionStrategy) Priority() int {
	return s.priority
}

func (s *CroppedRegionStrategy) ShouldRetry() bool {
	return true
}

func (s *CroppedRegionStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	startTime := time.Now()

	region, err := s.regionDetector.DetectIDNumberRegion(ctx, imageData)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	croppedData, err := s.regionDetector.CropRegion(ctx, imageData, region)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	upscaledData, err := s.imageProcessor.Upscale(ctx, croppedData, s.upscaleFactor)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	normalizedData, err := s.imageProcessor.Normalize(ctx, upscaledData)
	if err != nil {
		normalizedData = upscaledData
	}

	result, err := s.ocrProvider.ExtractText(ctx, normalizedData, &provider.OCROptions{
		Language: "eng",
		PSM:      7,
	})
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	idNumber, idErr := s.validator.ExtractIDNumber(result.Text)
	hasValidID := idErr == nil && idNumber != ""

	return &provider.StrategyResult{
		Name:           s.Name(),
		Success:        hasValidID,
		OCRResult:      result,
		ProcessingTime: time.Since(startTime),
		Metadata: map[string]interface{}{
			"id_found":       hasValidID,
			"id_number":      idNumber,
			"region":         region,
			"upscale_factor": s.upscaleFactor,
		},
	}, nil
}