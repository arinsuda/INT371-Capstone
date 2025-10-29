package strategy

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type NormalizedImageStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	validator      *validator.IDCardValidator
	cfg            *config.OCRConfig

	priority int
}

func NewNormalizedImageStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	validator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) *NormalizedImageStrategy {
	return &NormalizedImageStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		validator:      validator,
		cfg:            cfg,
		priority:       30,
	}
}

func (s *NormalizedImageStrategy) Name() string      { return "normalized" }
func (s *NormalizedImageStrategy) Priority() int     { return s.priority }
func (s *NormalizedImageStrategy) ShouldRetry() bool { return true }

func (s *NormalizedImageStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
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

	processed := imageData

	if g, err := s.imageProcessor.ConvertToGrayscale(ctx, processed); err == nil {
		processed = g
	} else {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          err,
			ProcessingTime: time.Since(start),
		}, nil
	}

	if doNormalize {
		if n, err := s.imageProcessor.Normalize(ctx, processed); err == nil {
			processed = n
		} else {

		}
	}

	if e, err := s.imageProcessor.EnhanceContrast(ctx, processed); err == nil {
		processed = e
	}

	psmCandidates := uniqueInts([]int{psm, 6, 7, 11})
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
