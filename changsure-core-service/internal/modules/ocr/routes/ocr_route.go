package routes

import (
	"changsure-core-service/internal/modules/ocr/handler"
	"github.com/gofiber/fiber/v3"
)

func RegisterOCRRoutes(r fiber.Router, h *handler.OCRHandler) {
	ocr := r.Group("/ocr")

	ocr.Get("/ping", h.Ping)
	ocr.Post("/upload", h.UploadAndScan)
}
