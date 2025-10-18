package strategy

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

// AutoRotateStrategy - หมุนภาพอัตโนมัติแล้ว OCR
type AutoRotateStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	validator      *validator.IDCardValidator
	language       string
	priority       int
}

func NewAutoRotateStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	validator *validator.IDCardValidator,
	language string,
) *AutoRotateStrategy {
	return &AutoRotateStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		validator:      validator,
		language:       language,
		priority:       70, // high priority
	}
}

func (s *AutoRotateStrategy) Name() string {
	return "auto_rotate"
}

func (s *AutoRotateStrategy) Priority() int {
	return s.priority
}

func (s *AutoRotateStrategy) ShouldRetry() bool {
	return false // no retry needed
}

func (s *AutoRotateStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	startTime := time.Now()

	// 1. Auto-rotate image
	rotatedData, angle, err := s.imageProcessor.AutoRotate(ctx, imageData)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(startTime),
		}, nil
	}

	// 2. Preprocess
	processedData, err := s.imageProcessor.Preprocess(ctx, rotatedData, &provider.PreprocessOptions{
		Normalize:       true,
		EnhanceContrast: true,
	})
	if err != nil {
		processedData = rotatedData // fallback
	}

	// 3. OCR
	result, err := s.ocrProvider.ExtractText(ctx, processedData, &provider.OCROptions{
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

	// 4. Validate ID
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
			"rotation_angle": angle,
		},
	}, nil
}