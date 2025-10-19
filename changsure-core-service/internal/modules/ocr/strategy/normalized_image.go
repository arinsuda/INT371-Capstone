package strategy

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type NormalizedImageStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	validator      *validator.IDCardValidator
	language       string
	priority       int
}

func NewNormalizedImageStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	validator *validator.IDCardValidator,
	language string,
) *NormalizedImageStrategy {
	return &NormalizedImageStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		validator:      validator,
		language:       language,
		priority:       30,
	}
}

func (s *NormalizedImageStrategy) Name() string {
	return "normalized_image"
}

func (s *NormalizedImageStrategy) Priority() int {
	return s.priority
}

func (s *NormalizedImageStrategy) ShouldRetry() bool {
	return true
}

func (s *NormalizedImageStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	startTime := time.Now()

	grayData, err := s.imageProcessor.ConvertToGrayscale(ctx, imageData)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	normalizedData, err := s.imageProcessor.Normalize(ctx, grayData)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	enhancedData, err := s.imageProcessor.EnhanceContrast(ctx, normalizedData)
	if err != nil {
		enhancedData = normalizedData
	}

	result, err := s.ocrProvider.ExtractText(ctx, enhancedData, &provider.OCROptions{
		Language: s.language,
		PSM:      6,
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
			"id_found":  hasValidID,
			"id_number": idNumber,
		},
	}, nil
}