package strategy

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

// FullImageStrategy - OCR ทั้งภาพ
type FullImageStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	validator      *validator.IDCardValidator
	language       string
	priority       int
}

func NewFullImageStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	validator *validator.IDCardValidator,
	language string,
) *FullImageStrategy {
	return &FullImageStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		validator:      validator,
		language:       language,
		priority:       50, // medium priority
	}
}

func (s *FullImageStrategy) Name() string {
	return "full_image"
}

func (s *FullImageStrategy) Priority() int {
	return s.priority
}

func (s *FullImageStrategy) ShouldRetry() bool {
	return true
}

func (s *FullImageStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	startTime := time.Now()

	// Preprocess image (normalize, enhance contrast)
	processedData, err := s.imageProcessor.Preprocess(ctx, imageData, &provider.PreprocessOptions{
		Normalize:       true,
		EnhanceContrast: true,
		Grayscale:       false,
	})
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	// OCR
	result, err := s.ocrProvider.ExtractText(ctx, processedData, &provider.OCROptions{
		Language: s.language,
		PSM:      6, // Assume uniform block of text
	})
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	// Validate ID
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