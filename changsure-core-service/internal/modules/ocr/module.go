package ocr

import (
	"changsure-core-service/internal/modules/ocr/config"
	"changsure-core-service/internal/modules/ocr/handler"
	"changsure-core-service/internal/modules/ocr/provider"
	"changsure-core-service/internal/modules/ocr/routes"

	"github.com/gofiber/fiber/v3"
)

func Register(app *fiber.App, cfg config.OCRConfig) {
	p := provider.NewOCRProvider(cfg)
	h := handler.NewOCRHandler(p.OCRService)

	api := app.Group("/api")
	routes.RegisterOCRRoutes(api, h)
}
