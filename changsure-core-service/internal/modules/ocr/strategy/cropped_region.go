package strategy

import (
	"context"
	"fmt"
	"time"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/validator"
)

type CroppedRegionStrategy struct {
	ocrProvider    provider.OCRProvider
	imageProcessor provider.ImageProcessor
	regionDetector provider.RegionDetector
	validator      *validator.IDCardValidator
	cfg            *config.OCRConfig

	priority int
}

func NewCroppedRegionStrategy(
	ocr provider.OCRProvider,
	processor provider.ImageProcessor,
	detector provider.RegionDetector,
	validator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) *CroppedRegionStrategy {
	return &CroppedRegionStrategy{
		ocrProvider:    ocr,
		imageProcessor: processor,
		regionDetector: detector,
		validator:      validator,
		cfg:            cfg,
		priority:       100,
	}
}

func (s *CroppedRegionStrategy) Name() string      { return "cropped" }
func (s *CroppedRegionStrategy) Priority() int     { return s.priority }
func (s *CroppedRegionStrategy) ShouldRetry() bool { return true }

func (s *CroppedRegionStrategy) Execute(ctx context.Context, imageData []byte) (*provider.StrategyResult, error) {
	start := time.Now()

	lang := "eng"
	psm := 6
	oem := 3
	upscale := 3.0
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
		if s.cfg.IDCard.UpscaleFactor > 0 {
			upscale = s.cfg.IDCard.UpscaleFactor
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

	var regions []*provider.Region

	if s.cfg != nil && s.cfg.IDCard.IDNumberRegion.Enabled {
		base := s.cfg.IDCard.IDNumberRegion

		regions = append(regions, &provider.Region{
			X: base.X, Y: base.Y, Width: base.Width, Height: base.Height, Type: "base",
		})

		regions = append(regions,

			&provider.Region{
				X: clamp01(base.X - 0.03), Y: base.Y,
				Width: base.Width, Height: base.Height, Type: "shift_left",
			},

			&provider.Region{
				X: clamp01(base.X + 0.03), Y: base.Y,
				Width: base.Width, Height: base.Height, Type: "shift_right",
			},

			&provider.Region{
				X: base.X, Y: clamp01(base.Y - 0.02),
				Width: base.Width, Height: base.Height, Type: "shift_up",
			},

			&provider.Region{
				X: base.X, Y: clamp01(base.Y + 0.02),
				Width: base.Width, Height: base.Height, Type: "shift_down",
			},

			&provider.Region{
				X: clamp01(base.X - 0.05), Y: base.Y,
				Width: clamp01(base.Width + 0.10), Height: base.Height, Type: "wider",
			},
		)
	} else {
		region, err := s.regionDetector.DetectIDNumberRegion(ctx, imageData)
		if err != nil || region == nil {
			return &provider.StrategyResult{
				Name:           s.Name(),
				Success:        false,
				Error:          fmt.Errorf("detect id region failed: %w", err),
				ProcessingTime: time.Since(start),
			}, nil
		}
		regions = append(regions, region)
	}

	var best *provider.OCRResult
	var bestRegion *provider.Region
	var bestPSM int

	for _, region := range regions {
		croppedData, err := s.regionDetector.CropRegion(ctx, imageData, region)
		if err != nil {
			continue
		}

		processed := croppedData

		if g, err := s.imageProcessor.ConvertToGrayscale(ctx, processed); err == nil {
			processed = g
		}

		if upscale > 1.0 {
			if u, err := s.imageProcessor.Upscale(ctx, processed, upscale); err == nil {
				processed = u
			}
		}

		if e, err := s.imageProcessor.EnhanceContrast(ctx, processed); err == nil {
			processed = e
		}

		if doNormalize {
			if n, err := s.imageProcessor.Normalize(ctx, processed); err == nil {
				processed = n
			}
		}

		psmModes := uniqueInts([]int{psm, 7, 13, 6})

		for _, try := range psmModes {
			res, err := s.ocrProvider.ExtractText(ctx, processed, &provider.OCROptions{
				Language: lang,
				PSM:      try,
				OEM:      oem,
			})
			if err != nil || res == nil {
				continue
			}

			if res.Metadata == nil {
				res.Metadata = make(map[string]interface{}, 4)
			}
			res.Metadata["psm_used"] = try
			res.Metadata["language"] = lang
			res.Metadata["oem"] = oem
			res.Metadata["region_type"] = region.Type

			id, idErr := s.validator.ExtractIDNumber(res.Text)
			hasID := idErr == nil && id != ""

			if stopOnSuccess && hasID && res.Confidence >= minConfidenceStop {
				return &provider.StrategyResult{
					Name:           s.Name(),
					Success:        true,
					OCRResult:      res,
					ProcessingTime: time.Since(start),
					Metadata: map[string]interface{}{
						"id_found":       true,
						"id_number":      id,
						"region":         region,
						"region_type":    region.Type,
						"upscale_factor": upscale,
					},
				}, nil
			}

			if best == nil ||
				(res.Confidence > best.Confidence) ||
				(res.Confidence == best.Confidence && len(res.Text) > len(best.Text)) {
				best = res
				bestRegion = region
				bestPSM = try
			}
		}
	}

	if best == nil {
		return &provider.StrategyResult{
			Name:           s.Name(),
			Success:        false,
			Error:          fmt.Errorf("ocr failed with all regions and psm modes"),
			ProcessingTime: time.Since(start),
		}, nil
	}

	id, idErr := s.validator.ExtractIDNumber(best.Text)
	hasID := idErr == nil && id != ""

	if best.Metadata == nil {
		best.Metadata = make(map[string]interface{}, 6)
	}
	best.Metadata["psm_used"] = bestPSM
	best.Metadata["raw_text_len"] = len(best.Text)
	best.Metadata["region_type"] = bestRegion.Type

	return &provider.StrategyResult{
		Name:           s.Name(),
		Success:        hasID || best.Text != "",
		OCRResult:      best,
		ProcessingTime: time.Since(start),
		Metadata: map[string]interface{}{
			"id_found":       hasID,
			"id_number":      id,
			"region":         bestRegion,
			"region_type":    bestRegion.Type,
			"upscale_factor": upscale,
		},
	}, nil
}
