package handler

import (
	"bytes"
	"io"

	"changsure-core-service/internal/modules/ocr/service"
	"github.com/gofiber/fiber/v3"
)

type OCRHandler struct {
	svc service.OCRService
}

func NewOCRHandler(svc service.OCRService) *OCRHandler {
	return &OCRHandler{svc: svc}
}

func (h *OCRHandler) UploadAndScan(c fiber.Ctx) error {
	fileHeader, err := c.FormFile("file")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "file required",
		})
	}

	file, err := fileHeader.Open()
	if err != nil {
		return c.Status(400).JSON(fiber.Map{
			"error": "cannot open file",
		})
	}
	defer file.Close()

	var buf bytes.Buffer
	if _, err := io.Copy(&buf, file); err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": "cannot read file",
		})
	}

	res, err := h.svc.ProcessOCR(buf.Bytes(), fileHeader.Filename)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{
			"error": err.Error(),
		})
	}

	return c.JSON(res)
}
