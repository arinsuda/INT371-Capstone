package routes

import (
    "github.com/gofiber/fiber/v3"
    ocrhandler "changsure-core-service/internal/modules/ocr/handler"
)

func Register(r fiber.Router, h *ocrhandler.OCRHandler) {
    ocr := r.Group("/ocr")
    ocr.Get("/health", h.HealthCheck)
    ocr.Get("/metrics", h.GetMetrics)
    ocr.Post("/id-card", h.ProcessIDCard)
    ocr.Post("/extract", h.ExtractText)
}