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

	// Provider / Processor / Detector
	ocrProvider, err := provider.NewTesseractExecProvider(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create OCR provider: %w", err)
	}
	imageProcessor := provider.NewDefaultImageProcessor() // ภายในรองรับลอจิกตาม opts ที่ส่งจาก strategy
	regionDetector := provider.NewDefaultRegionDetector() // อ่านค่าครอปจาก ENV ตามที่ปรับไว้ก่อนหน้า

	// Validators
	idValidator := validator.NewIDCardValidator()
	fileValidator := validator.NewFileValidator(cfg)

	// Infra: cache / metrics
	var cacheManager provider.CacheManager
	var metricsCollector provider.MetricsCollector
	if cfg.Performance.EnableCache {
		cacheManager = infra.NewMemoryCache()
	}
	if cfg.Performance.EnableMetrics {
		metricsCollector = infra.NewMetricsCollector()
	}

	// Build strategies จาก cfg (ผูกกับ .env เต็มที่)
	strategies := createStrategies(
		ocrProvider,
		imageProcessor,
		regionDetector,
		idValidator,
		cfg,
	)

	// Manager
	strategyManager := strategy.NewStrategyManager(
		strategies,
		cfg,
		cacheManager,
		metricsCollector,
	)

	// Service / Handler
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
	// สร้างเป็น map ก่อน เพื่อจัดเรียงตาม ExecutionOrder ได้ง่าย
	registry := map[string]provider.OCRStrategy{}

	if cfg.Strategies.EnableAggressiveCrop {
		registry["aggressive_crop"] = strategy.NewAggressiveCropStrategy(
			ocrProvider, imageProcessor, regionDetector, idValidator, cfg,
		)
	}
	if cfg.Strategies.EnableCroppedRegion {
		registry["cropped"] = strategy.NewCroppedRegionStrategy(
			ocrProvider, imageProcessor, regionDetector, idValidator, cfg,
			
		)
	}
	if cfg.IDCard.EnableAutoRotate {
		registry["auto_rotate"] = strategy.NewAutoRotateStrategy(
			ocrProvider, imageProcessor, idValidator, cfg,
		)
	}
	if cfg.Strategies.EnableFullImage {
		registry["full"] = strategy.NewFullImageStrategy(
			ocrProvider, imageProcessor, idValidator, cfg,
		)
	}
	if cfg.Strategies.EnableNormalizedImage {
		registry["normalized"] = strategy.NewNormalizedImageStrategy(
			ocrProvider, imageProcessor, idValidator, cfg,
		)
	}

	// ถ้าไม่มีอะไรเปิดไว้เลย ให้มีชุด fallback ที่อ่านค่าใน cfg ภายในกลยุทธ์เอง
	if len(registry) == 0 {
		registry["aggressive_crop"] = strategy.NewAggressiveCropStrategy(
			ocrProvider, imageProcessor, regionDetector, idValidator, cfg,
		)
		registry["cropped"] = strategy.NewCroppedRegionStrategy(
			ocrProvider, imageProcessor, regionDetector, idValidator, cfg,
		)
		registry["full"] = strategy.NewFullImageStrategy(
			ocrProvider, imageProcessor, idValidator, cfg,
		)
	}

	// จัดเรียงตาม ExecutionOrder จาก .env; ถ้าเว้นว่างใช้ลำดับมาตรฐาน
	order := cfg.Strategies.ExecutionOrder
	if len(order) == 0 {
		order = []string{"cropped", "aggressive_crop", "normalized", "auto_rotate", "full"}
	}

	out := make([]provider.OCRStrategy, 0, len(registry))
	used := map[string]bool{}
	for _, key := range order {
		if s, ok := registry[key]; ok {
			out = append(out, s)
			used[key] = true
		}
	}
	// เติมกลยุทธ์ที่เปิดไว้แต่ไม่อยู่ใน order (กันตกหล่น)
	for k, s := range registry {
		if !used[k] {
			out = append(out, s)
		}
	}
	return out
}

func NewModule() (*OCRModule, error) { return NewOCRModule() }

func (m *OCRModule) Close() error {
	if m.Service != nil {
		return m.Service.Close()
	}
	return nil
}
