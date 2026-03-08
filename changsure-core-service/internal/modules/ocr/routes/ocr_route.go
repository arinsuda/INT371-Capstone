package routes

import (
	"changsure-core-service/internal/modules/ocr/handler"

	"github.com/gofiber/fiber/v3"
)

func RegisterOCRRoutes(r fiber.Router, h *handler.OCRHandler) {
	r.Get("/ocr/ping", h.Ping)          // GET  /api/ocr/ping   — ตรวจสอบ connectivity
	r.Post("/ocr/upload", h.UploadAndScan) // POST /api/ocr/upload — scan รูป
}