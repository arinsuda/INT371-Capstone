package handler

import (
	"strconv"
	"strings"
	"time"

	"changsure-core-service/internal/modules/ocr/dto"
	"changsure-core-service/internal/modules/ocr/service"
	"changsure-core-service/internal/modules/ocr/validator"

	"github.com/gofiber/fiber/v3"
)

type OCRHandler struct {
	ocrService    *service.OCRService
	fileValidator *validator.FileValidator
}

func NewOCRHandler(ocrService *service.OCRService, fileValidator *validator.FileValidator) *OCRHandler {
	return &OCRHandler{
		ocrService:    ocrService,
		fileValidator: fileValidator,
	}
}

// ProcessIDCard godoc
// @Summary Process Thai ID Card
// @Description Extract information from Thai ID card image
// @Tags OCR
// @Accept multipart/form-data
// @Produce json
// @Param image formData file true "ID Card Image"
// @Param preprocess_image formData bool false "Enable image preprocessing" default(true)
// @Param auto_rotate formData bool false "Enable auto rotation" default(true)
// @Param validate_checksum formData bool false "Validate ID checksum" default(true)
// @Param language formData string false "OCR Language" default(tha+eng)
// @Param enable_concurrent formData bool false "Enable concurrent processing" default(true)
// @Param stop_on_success formData bool false "Stop on first success" default(true)
// @Param min_confidence formData number false "Minimum confidence threshold" default(0.85)
// @Param timeout formData int false "Timeout in seconds" default(15)
// @Success 200 {object} dto.OCRResponse
// @Failure 400 {object} dto.OCRResponse
// @Failure 500 {object} dto.OCRResponse
// @Router /api/ocr/id-card [post]
func (h *OCRHandler) ProcessIDCard(c fiber.Ctx) error {
	// 1. Get file from form
	fileHeader, err := c.FormFile("image")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(dto.NewErrorResponse(
			dto.ErrCodeInvalidInput,
			"No image file provided",
		))
	}

	// Validate file
	if err := h.fileValidator.ValidateFile(fileHeader); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(dto.NewErrorResponse(
			dto.ErrCodeInvalidFormat,
			err.Error(),
		))
	}

	// Read file bytes
	imageData, err := validator.ReadFileBytes(fileHeader)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(dto.NewErrorResponse(
			dto.ErrCodeInternalError,
			"Failed to read image file",
		))
	}

	// 2. Parse request from form values
	req := &dto.IDCardRequest{
		OCRRequest: dto.OCRRequest{
			PreprocessImage:  parseBoolForm(c, "preprocess_image", true),
			AutoRotate:       parseBoolForm(c, "auto_rotate", true),
			NormalizeImage:   parseBoolForm(c, "normalize_image", true),
			ValidateChecksum: parseBoolForm(c, "validate_checksum", true),
			Language:         parseStringForm(c, "language", "eng"), // ใช้ eng สำหรับตัวเลข
			EnableConcurrent: parseBoolForm(c, "enable_concurrent", true),
			StopOnSuccess:    parseBoolForm(c, "stop_on_success", true),
			MinConfidence:    parseFloatForm(c, "min_confidence", 0.80), // ลดเหลือ 0.80
			Timeout:          parseIntForm(c, "timeout", 20), // เพิ่ม timeout เป็น 20s
		},
		ExtractName:    parseBoolForm(c, "extract_name", false),
		ExtractDOB:     parseBoolForm(c, "extract_dob", false),
		ExtractAddress: parseBoolForm(c, "extract_address", false),
	}

	// Set defaults
	req.SetDefaults()

	// Parse strategies if provided
	if strategiesStr := c.FormValue("strategies"); strategiesStr != "" {
		req.Strategies = parseStrategies(strategiesStr)
	}

	// 3. Process ID card
	result, metadata, err := h.ocrService.ProcessIDCard(c.Context(), imageData, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(dto.NewErrorResponse(
			dto.ErrCodeProcessingFailed,
			err.Error(),
		))
	}

	// 4. Build response
	response := &dto.OCRResponse{
		Success:  result.IsValid,
		Metadata: metadata,
	}

	// Build custom data structure for ID card
	responseData := map[string]interface{}{
		"raw_text":       result.RawText,
		"confidence":     result.Confidence,
		"language":       result.Language,
		"is_valid":       result.IsValid,
		"warnings":       result.Warnings,
		"id_number":      result.IDNumber,
		"checksum_valid": result.ChecksumValid,
		"format_valid":   result.FormatValid,
	}

	// Set timestamp
	response.Timestamp = time.Now()

	// 5. Return response with custom data
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success":   response.Success,
		"data":      responseData,
		"metadata":  response.Metadata,
		"timestamp": response.Timestamp,
	})
}

// ExtractText godoc
// @Summary Extract text from image
// @Description Extract text from any image (not specific to ID card)
// @Tags OCR
// @Accept multipart/form-data
// @Produce json
// @Param image formData file true "Image file"
// @Param preprocess_image formData bool false "Enable image preprocessing" default(true)
// @Param language formData string false "OCR Language" default(tha+eng)
// @Param timeout formData int false "Timeout in seconds" default(15)
// @Success 200 {object} dto.OCRResponse
// @Failure 400 {object} dto.OCRResponse
// @Failure 500 {object} dto.OCRResponse
// @Router /api/ocr/extract [post]
func (h *OCRHandler) ExtractText(c fiber.Ctx) error {
	// 1. Get file from form
	fileHeader, err := c.FormFile("image")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(dto.NewErrorResponse(
			dto.ErrCodeInvalidInput,
			"No image file provided",
		))
	}

	if err := h.fileValidator.ValidateFile(fileHeader); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(dto.NewErrorResponse(
			dto.ErrCodeInvalidFormat,
			err.Error(),
		))
	}

	imageData, err := validator.ReadFileBytes(fileHeader)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(dto.NewErrorResponse(
			dto.ErrCodeInternalError,
			"Failed to read image file",
		))
	}

	// 2. Parse request
	req := &dto.OCRRequest{
		PreprocessImage: parseBoolForm(c, "preprocess_image", true),
		Language:        parseStringForm(c, "language", "tha+eng"),
		Timeout:         parseIntForm(c, "timeout", 15),
	}
	req.SetDefaults()

	// 3. Extract text
	result, metadata, err := h.ocrService.ExtractText(c.Context(), imageData, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(dto.NewErrorResponse(
			dto.ErrCodeOCRFailed,
			err.Error(),
		))
	}

	// 4. Return response
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": result.IsValid,
		"data": fiber.Map{
			"raw_text":   result.RawText,
			"confidence": result.Confidence,
			"language":   result.Language,
			"is_valid":   result.IsValid,
			"warnings":   result.Warnings,
		},
		"metadata":  metadata,
		"timestamp": time.Now(),
	})
}

// GetMetrics godoc
// @Summary Get OCR metrics
// @Description Get performance metrics for OCR strategies
// @Tags OCR
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /api/ocr/metrics [get]
func (h *OCRHandler) GetMetrics(c fiber.Ctx) error {
	metrics := h.ocrService.GetMetrics()
	if metrics == nil {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"message": "Metrics collection is disabled",
		})
	}

	return c.Status(fiber.StatusOK).JSON(metrics)
}

// HealthCheck godoc
// @Summary Health check
// @Description Check if OCR service is healthy
// @Tags OCR
// @Produce json
// @Success 200 {object} map[string]interface{}
// @Router /api/ocr/health [get]
func (h *OCRHandler) HealthCheck(c fiber.Ctx) error {
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"status":  "healthy",
		"service": "ocr",
		"version": "2.0.0",
	})
}

// ============================================
// Helper functions for Fiber v3
// ============================================

func parseBoolForm(c fiber.Ctx, key string, defaultValue bool) bool {
	if value := c.FormValue(key); value != "" {
		if b, err := strconv.ParseBool(value); err == nil {
			return b
		}
	}
	return defaultValue
}

func parseFloatForm(c fiber.Ctx, key string, defaultValue float64) float64 {
	if value := c.FormValue(key); value != "" {
		if f, err := strconv.ParseFloat(value, 64); err == nil {
			return f
		}
	}
	return defaultValue
}

func parseIntForm(c fiber.Ctx, key string, defaultValue int) int {
	if value := c.FormValue(key); value != "" {
		if i, err := strconv.Atoi(value); err == nil {
			return i
		}
	}
	return defaultValue
}

func parseStringForm(c fiber.Ctx, key string, defaultValue string) string {
	if value := c.FormValue(key); value != "" {
		return value
	}
	return defaultValue
}

func parseStrategies(strategiesStr string) []string {
	strategies := []string{}
	for _, s := range strings.Split(strategiesStr, ",") {
		trimmed := strings.TrimSpace(s)
		if trimmed != "" {
			strategies = append(strategies, trimmed)
		}
	}
	return strategies
}