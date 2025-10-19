package ocr

import (
	"fmt"

	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/handler"
	"changsure-core-service/internal/modules/ocr/infra"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/service"
	"changsure-core-service/internal/modules/ocr/strategy"
	"changsure-core-service/internal/modules/ocr/validator"
)

type OCRModule struct {
	Handler *handler.OCRHandler
	Service *service.OCRService
	Config  *config.OCRConfig
}

func NewOCRModule() (*OCRModule, error) {

	cfg := config.LoadOCRConfig()

	ocrProvider, err := provider.NewTesseractExecProvider(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create OCR provider: %w", err)
	}

	imageProcessor := provider.NewDefaultImageProcessor()
	regionDetector := provider.NewDefaultRegionDetector()

	idValidator := validator.NewIDCardValidator()
	fileValidator := validator.NewFileValidator(cfg)

	var cacheManager provider.CacheManager
	var metricsCollector provider.MetricsCollector

	if cfg.Performance.EnableCache {
		cacheManager = infra.NewMemoryCache()
	}

	if cfg.Performance.EnableMetrics {
		metricsCollector = infra.NewMetricsCollector()
	}

	strategies := createStrategies(
		ocrProvider,
		imageProcessor,
		regionDetector,
		idValidator,
		cfg,
	)

	strategyManager := strategy.NewStrategyManager(
		strategies,
		cfg,
		cacheManager,
		metricsCollector,
	)

	ocrService := service.NewOCRService(
		strategyManager,
		idValidator,
		metricsCollector,
		cfg,
	)

	ocrHandler := handler.NewOCRHandler(ocrService, fileValidator)

	return &OCRModule{
		Handler: ocrHandler,
		Service: ocrService,
		Config:  cfg,
	}, nil
}

func createStrategies(
	ocrProvider provider.OCRProvider,
	imageProcessor provider.ImageProcessor,
	regionDetector provider.RegionDetector,
	idValidator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) []provider.OCRStrategy {
	language := cfg.Language
	strategies := []provider.OCRStrategy{}

	if cfg.Strategies.EnableAggressiveCrop {
		strategies = append(strategies, strategy.NewAggressiveCropStrategy(
			ocrProvider,
			imageProcessor,
			regionDetector,
			idValidator,
			3.0,
		))
	}

	if cfg.Strategies.EnableCroppedRegion {
		strategies = append(strategies, strategy.NewCroppedRegionStrategy(
			ocrProvider,
			imageProcessor,
			regionDetector,
			idValidator,
			language,
			cfg.IDCard.UpscaleFactor,
		))
	}

	if cfg.IDCard.EnableAutoRotate {
		strategies = append(strategies, strategy.NewAutoRotateStrategy(
			ocrProvider,
			imageProcessor,
			idValidator,
			language,
		))
	}

	if cfg.Strategies.EnableFullImage {
		strategies = append(strategies, strategy.NewFullImageStrategy(
			ocrProvider,
			imageProcessor,
			idValidator,
			language,
		))
	}

	if cfg.Strategies.EnableNormalizedImage {
		strategies = append(strategies, strategy.NewNormalizedImageStrategy(
			ocrProvider,
			imageProcessor,
			idValidator,
			language,
		))
	}

	if len(strategies) == 0 {
		strategies = []provider.OCRStrategy{
			strategy.NewAggressiveCropStrategy(
				ocrProvider,
				imageProcessor,
				regionDetector,
				idValidator,
				3.0,
			),
			strategy.NewCroppedRegionStrategy(
				ocrProvider,
				imageProcessor,
				regionDetector,
				idValidator,
				language,
				2.0,
			),
			strategy.NewFullImageStrategy(
				ocrProvider,
				imageProcessor,
				idValidator,
				language,
			),
		}
	}

	return strategies
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

func NewModule() (*OCRModule, error) {
	return NewOCRModule()
}

func (m *OCRModule) Close() error {
	if m.Service != nil {
		return m.Service.Close()
	}
	return nil
}