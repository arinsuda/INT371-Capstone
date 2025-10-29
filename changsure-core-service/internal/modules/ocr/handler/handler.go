package handler

import (
	"os"
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

func (h *OCRHandler) ProcessIDCard(c fiber.Ctx) error {
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

	defaultPreprocess := envBool("ENABLE_PREPROCESSING", true)
	defaultAutoRotate := envBool("OCR_AUTO_ROTATE", true)
	defaultNormalize := envBool("OCR_NORMALIZE", true)
	defaultValidateChecksum := envBool("OCR_VALIDATE_CHECKSUM", true)
	defaultLanguage := envString("OCR_LANGUAGE", "eng")
	defaultConcurrent := envBool("OCR_CONCURRENT", true)
	defaultStopOnSuccess := envBool("OCR_STOP_ON_SUCCESS", true)
	defaultMinConf := envFloat("OCR_MIN_CONFIDENCE_STOP", 0.60)
	defaultTimeout := envInt("OCR_TIMEOUT", 30)

	req := &dto.IDCardRequest{
		OCRRequest: dto.OCRRequest{
			PreprocessImage:  parseBoolForm(c, "preprocess_image", defaultPreprocess),
			AutoRotate:       parseBoolForm(c, "auto_rotate", defaultAutoRotate),
			NormalizeImage:   parseBoolForm(c, "normalize_image", defaultNormalize),
			ValidateChecksum: parseBoolForm(c, "validate_checksum", defaultValidateChecksum),
			Language:         parseStringForm(c, "language", defaultLanguage),
			EnableConcurrent: parseBoolForm(c, "enable_concurrent", defaultConcurrent),
			StopOnSuccess:    parseBoolForm(c, "stop_on_success", defaultStopOnSuccess),
			MinConfidence:    parseFloatForm(c, "min_confidence", defaultMinConf),
			Timeout:          parseIntForm(c, "timeout", defaultTimeout),
		},
		ExtractName:    parseBoolForm(c, "extract_name", envBool("OCR_EXTRACT_NAME", false)),
		ExtractDOB:     parseBoolForm(c, "extract_dob", envBool("OCR_EXTRACT_DOB", false)),
		ExtractAddress: parseBoolForm(c, "extract_address", envBool("OCR_EXTRACT_ADDRESS", false)),
	}

	if strategiesStr := c.FormValue("strategies"); strategiesStr != "" {
		req.Strategies = parseStrategies(strategiesStr)
	} else {
		req.Strategies = envStrategies()
	}

	req.SetDefaults()

	result, metadata, err := h.ocrService.ProcessIDCard(c.Context(), imageData, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(dto.NewErrorResponse(
			dto.ErrCodeProcessingFailed,
			err.Error(),
		))
	}

	response := &dto.OCRResponse{
		Success:  result.IsValid,
		Metadata: metadata,
	}

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

	response.Timestamp = time.Now()

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success":   response.Success,
		"data":      responseData,
		"metadata":  response.Metadata,
		"timestamp": response.Timestamp,
	})
}

func (h *OCRHandler) ExtractText(c fiber.Ctx) error {
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

	defaultPreprocess := envBool("ENABLE_PREPROCESSING", true)
	defaultLanguage := envString("OCR_LANGUAGE", "eng")
	defaultTimeout := envInt("OCR_TIMEOUT_EXTRACT", envInt("OCR_TIMEOUT", 15))

	req := &dto.OCRRequest{
		PreprocessImage: parseBoolForm(c, "preprocess_image", defaultPreprocess),
		Language:        parseStringForm(c, "language", defaultLanguage),
		Timeout:         parseIntForm(c, "timeout", defaultTimeout),
	}
	req.SetDefaults()

	result, metadata, err := h.ocrService.ExtractText(c.Context(), imageData, req)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(dto.NewErrorResponse(
			dto.ErrCodeOCRFailed,
			err.Error(),
		))
	}

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

func (h *OCRHandler) GetMetrics(c fiber.Ctx) error {
	metrics := h.ocrService.GetMetrics()
	if metrics == nil {
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"message": "Metrics collection is disabled",
		})
	}

	return c.Status(fiber.StatusOK).JSON(metrics)
}

func (h *OCRHandler) HealthCheck(c fiber.Ctx) error {
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"status":  "healthy",
		"service": "ocr",
		"version": "2.0.0",
	})
}

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

func envString(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func envBool(key string, def bool) bool {
	if v := os.Getenv(key); v != "" {
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return def
}

func envInt(key string, def int) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return def
}

func envFloat(key string, def float64) float64 {
	if v := os.Getenv(key); v != "" {
		if f, err := strconv.ParseFloat(v, 64); err == nil {
			return f
		}
	}
	return def
}

func envStrategies() []string {
	out := make([]string, 0, 4)
	if envBool("OCR_STRATEGY_AGGRESSIVE", false) {
		out = append(out, "aggressive")
	}
	if envBool("OCR_STRATEGY_FULL", false) {
		out = append(out, "full")
	}
	if envBool("OCR_STRATEGY_CROPPED", false) {
		out = append(out, "cropped")
	}
	if envBool("OCR_STRATEGY_NORMALIZED", false) {
		out = append(out, "normalized")
	}
	if len(out) == 0 {
		out = append(out, "full")
	}
	return out
}
