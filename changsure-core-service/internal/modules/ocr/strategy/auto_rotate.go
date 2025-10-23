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
		priority:       70,
	}
}

func (s *AutoRotateStrategy) Name() string      { return "auto_rotate" }
func (s *AutoRotateStrategy) Priority() int     { return s.priority }
func (s *AutoRotateStrategy) ShouldRetry() bool { return false }

func (s *AutoRotateStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	start := time.Now()

	lang := "eng"
	if s.cfg != nil && s.cfg.Language != "" {
		lang = s.cfg.Language
	}

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

	doNormalize := true
	if s.cfg != nil {
		doNormalize = s.cfg.IDCard.EnableNormalize
	}

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

	if s.cfg != nil && s.cfg.Performance.StrategyTimeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, s.cfg.Performance.StrategyTimeout)
		defer cancel()
	}

	rotatedData, angle, err := s.imageProcessor.AutoRotate(ctx, imageData)
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(start),
		}, nil
	}

	processedData, err := s.imageProcessor.Preprocess(ctx, rotatedData, &provider.PreprocessOptions{
		Grayscale:       true,
		Normalize:       doNormalize,
		EnhanceContrast: true,
	})
	if err != nil {
		processedData = rotatedData
	}

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

		if best == nil || (candidate.OCRResult != nil && best.OCRResult != nil &&
			candidate.OCRResult.Confidence > best.OCRResult.Confidence) {
			best = candidate
		}

		if stopOnSuccess && hasValidID && res.Confidence >= minConfidenceStop {
			return candidate, nil
		}
	}

	if best != nil {
		return best, nil
	}

	return &provider.StrategyResult{
		Name:           s.Name(),
		Success:        false,
		ProcessingTime: time.Since(start),
	}, nil
}
