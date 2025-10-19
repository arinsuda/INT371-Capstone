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

// OCRModule เป็น main module
type OCRModule struct {
	Handler *handler.OCRHandler
	Service *service.OCRService
	Config  *config.OCRConfig
}

// NewOCRModule สร้าง OCR module พร้อม dependencies ทั้งหมด
func NewOCRModule() (*OCRModule, error) {
	// 1. Load config
	cfg := config.LoadOCRConfig()

	// 2. สร้าง core providers
	ocrProvider, err := provider.NewTesseractExecProvider(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create OCR provider: %w", err)
	}

	imageProcessor := provider.NewDefaultImageProcessor()
	regionDetector := provider.NewDefaultRegionDetector()

	// 3. สร้าง validators
	idValidator := validator.NewIDCardValidator()
	fileValidator := validator.NewFileValidator(cfg)

	// 4. สร้าง cache และ metrics
	var cacheManager provider.CacheManager
	var metricsCollector provider.MetricsCollector

	if cfg.Performance.EnableCache {
		cacheManager = infra.NewMemoryCache()
	}

	if cfg.Performance.EnableMetrics {
		metricsCollector = infra.NewMetricsCollector()
	}

	// 5. สร้าง strategies
	strategies := createStrategies(
		ocrProvider,
		imageProcessor,
		regionDetector,
		idValidator,
		cfg,
	)

	// 6. สร้าง strategy manager
	strategyManager := strategy.NewStrategyManager(
		strategies,
		cfg,
		cacheManager,
		metricsCollector,
	)

	// 7. สร้าง service
	ocrService := service.NewOCRService(
		strategyManager,
		idValidator,
		metricsCollector,
		cfg,
	)

	// 8. สร้าง handler
	ocrHandler := handler.NewOCRHandler(ocrService, fileValidator)

	return &OCRModule{
		Handler: ocrHandler,
		Service: ocrService,
		Config:  cfg,
	}, nil
}

// createStrategies สร้าง strategies ทั้งหมด (เรียงตาม priority)
func createStrategies(
	ocrProvider provider.OCRProvider,
	imageProcessor provider.ImageProcessor,
	regionDetector provider.RegionDetector,
	idValidator *validator.IDCardValidator,
	cfg *config.OCRConfig,
) []provider.OCRStrategy {
	language := cfg.Language
	strategies := []provider.OCRStrategy{}

	// 🆕 Strategy 1: Aggressive Crop (Priority 110 - สูงสุด)
	// เหมาะสำหรับบัตรที่มี barcode, chip, photo
	if cfg.Strategies.EnableAggressiveCrop {
		strategies = append(strategies, strategy.NewAggressiveCropStrategy(
			ocrProvider,
			imageProcessor,
			regionDetector,
			idValidator,
			3.0, // upscale 3x สำหรับความละเอียดสูง
		))
	}

	// Strategy 2: Cropped Region (Priority 100)
	// เหมาะสำหรับบัตรทั่วไป
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

	// Strategy 3: Auto Rotate (Priority 70)
	// เหมาะสำหรับภาพที่หมุน
	if cfg.IDCard.EnableAutoRotate {
		strategies = append(strategies, strategy.NewAutoRotateStrategy(
			ocrProvider,
			imageProcessor,
			idValidator,
			language,
		))
	}

	// Strategy 4: Full Image (Priority 50)
	// เหมาะสำหรับภาพที่มีแค่เลขบัตร
	if cfg.Strategies.EnableFullImage {
		strategies = append(strategies, strategy.NewFullImageStrategy(
			ocrProvider,
			imageProcessor,
			idValidator,
			language,
		))
	}

	// Strategy 5: Normalized Image (Priority 30)
	// เหมาะสำหรับภาพที่มีปัญหาแสง/contrast
	if cfg.Strategies.EnableNormalizedImage {
		strategies = append(strategies, strategy.NewNormalizedImageStrategy(
			ocrProvider,
			imageProcessor,
			idValidator,
			language,
		))
	}

	// ถ้าไม่มี strategy เลย ใช้ default strategies
	if len(strategies) == 0 {
		strategies = []provider.OCRStrategy{
			// Default: ใช้ Aggressive Crop + Cropped Region
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

// contains ตรวจสอบว่า slice มี item หรือไม่
func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}

// NewModule alias สำหรับความเข้ากันได้
func NewModule() (*OCRModule, error) {
	return NewOCRModule()
}

// Close ปิด module
func (m *OCRModule) Close() error {
	if m.Service != nil {
		return m.Service.Close()
	}
	return nil
}