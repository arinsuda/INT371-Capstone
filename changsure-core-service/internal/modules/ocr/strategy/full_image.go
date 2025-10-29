package strategy

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type FullImageStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	validator      *validator.IDCardValidator
	cfg            *config.OCRConfig

	priority int
}

func NewFullImageStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	validator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) *FullImageStrategy {
	return &FullImageStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		validator:      validator,
		cfg:            cfg,
		priority:       50,
	}
}

func (s *FullImageStrategy) Name() string      { return "full" }
func (s *FullImageStrategy) Priority() int     { return s.priority }
func (s *FullImageStrategy) ShouldRetry() bool { return true }

func (s *FullImageStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	start := time.Now()

	lang := "eng"
	psm := 6
	oem := 3
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

		doNormalize = s.cfg.IDCard.EnableNormalize

		stopOnSuccess = s.cfg.StopOnSuccess || s.cfg.Strategies.StopOnFirstSuccess
		if s.cfg.MinConfidenceStop > 0 {
			minConfidenceStop = s.cfg.MinConfidenceStop
		}
		if s.cfg.Strategies.MinConfidenceToStop > 0 {
			minConfidenceStop = s.cfg.Strategies.MinConfidenceToStop
		}

		if s.cfg.Performance.StrategyTimeout > 0 {
			var cancel context.CancelFunc
			ctx, cancel = context.WithTimeout(ctx, s.cfg.Performance.StrategyTimeout)
			defer cancel()
		}
	}

	processed, err := s.imageProcessor.Preprocess(ctx, imageData, &provider.PreprocessOptions{
		Grayscale:       true,
		Normalize:       doNormalize,
		EnhanceContrast: true,
	})
	if err != nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(start),
		}, nil
	}

	psmCandidates := uniqueInts([]int{psm, 6, 3, 11})
	var best *provider.StrategyResult

	for _, try := range psmCandidates {
		res, err := s.ocrProvider.ExtractText(ctx, processed, &provider.OCROptions{
			Language: lang,
			PSM:      try,
			OEM:      oem,
		})
		if err != nil || res == nil {
			continue
		}

		idNumber, idErr := s.validator.ExtractIDNumber(res.Text)
		hasID := idErr == nil && idNumber != ""

		candidate := &provider.StrategyResult{
			Name:           s.Name(),
			Success:        hasID,
			OCRResult:      res,
			ProcessingTime: time.Since(start),
			Metadata: map[string]interface{}{
				"id_found":  hasID,
				"id_number": idNumber,
				"language":  lang,
				"psm":       try,
				"oem":       oem,
			},
		}

		if stopOnSuccess && hasID && res.Confidence >= minConfidenceStop {
			return candidate, nil
		}

		if best == nil || (candidate.OCRResult != nil && best.OCRResult != nil &&
			candidate.OCRResult.Confidence > best.OCRResult.Confidence) {
			best = candidate
		}
	}

	if best == nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			ProcessingTime: time.Since(start),
		}, nil
	}

	return best, nil
}
