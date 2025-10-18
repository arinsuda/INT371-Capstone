package routes

import (
	"changsure-core-service/internal/modules/ocr"
	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/handler"
	"changsure-core-service/internal/modules/ocr/validator"

	"github.com/gofiber/fiber/v3"
)

// SetupOCRRoutes ตั้งค่า routes สำหรับ OCR module
func SetupOCRRoutes(app *fiber.App) error {
	// 1. Load config
	cfg := config.LoadOCRConfig()

	// 2. Initialize OCR module
	ocrModule, err := ocr.NewOCRModule()
	if err != nil {
		return err
	}

	// 3. Create validators
	fileValidator := validator.NewFileValidator(cfg)

	// 4. Create handler
	ocrHandler := handler.NewOCRHandler(ocrModule.Service, fileValidator)

	// 5. Setup routes
	api := app.Group("/api")
	ocrGroup := api.Group("/ocr")
	
	// Health check
	ocrGroup.Get("/health", ocrHandler.HealthCheck)

	// Metrics
	ocrGroup.Get("/metrics", ocrHandler.GetMetrics)

	// OCR endpoints
	ocrGroup.Post("/id-card", ocrHandler.ProcessIDCard)
	ocrGroup.Post("/extract", ocrHandler.ExtractText)

	return nil
}

// SetupOCRRoutesWithMiddleware ตั้งค่า routes พร้อม middleware
func SetupOCRRoutesWithMiddleware(app *fiber.App, middlewares ...any) error {
	// 1. Load config
	cfg := config.LoadOCRConfig()

	// 2. Initialize OCR module
	ocrModule, err := ocr.NewOCRModule()
	if err != nil {
		return err
	}

	// 3. Create validators
	fileValidator := validator.NewFileValidator(cfg)

	// 4. Create handler
	ocrHandler := handler.NewOCRHandler(ocrModule.Service, fileValidator)

	// 5. Setup routes with middleware
	api := app.Group("/api")
	
	// Apply middlewares to all API routes
	if len(middlewares) > 0 {
		api.Use(middlewares...)
	}
	
	ocrGroup := api.Group("/ocr")
	
	// Public endpoints (no auth)
	ocrGroup.Get("/health", ocrHandler.HealthCheck)

	// Protected endpoints (with auth middleware if needed)
	protected := ocrGroup.Group("")
	// protected.Use(AuthMiddleware()) // Add your auth middleware here
	
	protected.Get("/metrics", ocrHandler.GetMetrics)
	protected.Post("/id-card", ocrHandler.ProcessIDCard)
	protected.Post("/extract", ocrHandler.ExtractText)

	return nil
}

// SetupOCRRoutesAdvanced ตั้งค่า routes แบบ advanced พร้อม rate limiting
func SetupOCRRoutesAdvanced(app *fiber.App, rateLimiter any, authMiddleware any) error {
	// 1. Load config
	cfg := config.LoadOCRConfig()

	// 2. Initialize OCR module
	ocrModule, err := ocr.NewOCRModule()
	if err != nil {
		return err
	}

	// 3. Create validators
	fileValidator := validator.NewFileValidator(cfg)

	// 4. Create handler
	ocrHandler := handler.NewOCRHandler(ocrModule.Service, fileValidator)

	// 5. Setup routes
	api := app.Group("/api")
	ocrGroup := api.Group("/ocr")
	
	// Public endpoints (with rate limiting)
	ocrGroup.Get("/health", ocrHandler.HealthCheck)

	// Protected endpoints (with auth + rate limiting)
	protected := ocrGroup.Group("")
	if authMiddleware != nil {
		protected.Use(authMiddleware)
	}
	if rateLimiter != nil {
		protected.Use(rateLimiter)
	}
	
	protected.Get("/metrics", ocrHandler.GetMetrics)
	protected.Post("/id-card", ocrHandler.ProcessIDCard)
	protected.Post("/extract", ocrHandler.ExtractText)

	return nil
}