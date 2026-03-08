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
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "FILE_REQUIRED",
			"message": "กรุณาแนบไฟล์รูปภาพ (field: file)",
		})
	}

	file, err := fileHeader.Open()
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "FILE_OPEN_FAILED",
			"message": "ไม่สามารถเปิดไฟล์ได้",
		})
	}
	defer file.Close()

	var buf bytes.Buffer
	if _, err := io.Copy(&buf, file); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "FILE_READ_FAILED",
			"message": "ไม่สามารถอ่านไฟล์ได้",
		})
	}

	res, err := h.svc.ProcessOCR(buf.Bytes(), fileHeader.Filename)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"error":   "OCR_FAILED",
			"message": err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    res,
	})
}