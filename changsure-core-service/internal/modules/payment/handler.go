package payment

import (
	technicianbooking "changsure-core-service/internal/modules/technician_booking"
	"changsure-core-service/internal/realtime"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strconv"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service    Service
	bookingSvc technicianbooking.Service
	hub        *realtime.Hub
	validator  *validator.Validate
	isTestMode bool

	webhookSecret string
}

func NewHandler(
	service Service,
	hub *realtime.Hub,
	webhookSecret string,
	isTestMode bool,
) *Handler {
	return &Handler{
		service:       service,
		hub:           hub,
		validator:     validator.New(),
		isTestMode:    isTestMode,
		webhookSecret: webhookSecret,
	}
}

func (h *Handler) GenerateQR(c fiber.Ctx) error {
	req := new(CreateQRRequest)
	if err := c.Bind().JSON(req); err != nil {
		return h.respondError(c, http.StatusBadRequest, "INVALID_REQUEST_FORMAT", "invalid format", err)
	}

	response, err := h.service.CreatePaymentQR(c.Context(), req)
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusOK).JSON(response)
}

func (h *Handler) GetPaymentSource(c fiber.Ctx) error {
	sourceID := c.Params("source_id")

	if sourceID == "" {
		return h.respondError(c, http.StatusBadRequest, "INVALID_SOURCE_ID", "source ID is required", nil)
	}

	source, err := h.service.GetPaymentSource(c.Context(), sourceID)
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusOK).JSON(source)
}

func (h *Handler) SimulatePaymentSuccess(c fiber.Ctx) error {
	if !h.isTestMode {
		return h.respondError(
			c,
			http.StatusForbidden,
			"NOT_ALLOWED",
			"simulation only available in test mode",
			nil,
		)
	}

	type SimulateRequest struct {
		SourceID  string  `json:"source_id" validate:"required"`
		BookingID uint    `json:"booking_id" validate:"required"`
		Amount    float64 `json:"amount" validate:"required,gt=0"`
	}

	req := new(SimulateRequest)
	if err := c.Bind().JSON(req); err != nil {
		return h.respondError(c, 400, "INVALID_REQUEST", "invalid format", err)
	}

	if err := h.validator.Struct(req); err != nil {
		return h.respondValidationError(c, err)
	}

	if err := h.service.ConfirmPayment(c.Context(), req.BookingID); err != nil {
		return h.handleServiceError(c, err)
	}

	h.triggerPaymentSuccess(req.SourceID, req.BookingID, req.Amount)

	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "payment success simulated",
	})
}

func (h *Handler) OmiseWebhook(c fiber.Ctx) error {
	rawBody := c.Request().Body()

	signature := c.Get("Omise-Signature")
	if signature == "" {
		signature = c.Get("X-Omise-Signature")
	}

	if !h.isTestMode {
		if signature == "" {
			return c.Status(fiber.StatusUnauthorized).
				JSON(fiber.Map{"error": "missing signature"})
		}

		if !VerifyOmiseSignature(rawBody, signature, h.webhookSecret) {
			return c.Status(fiber.StatusUnauthorized).
				JSON(fiber.Map{"error": "invalid signature"})
		}
	} else {
		log.Printf("⚠️  Test mode: skipping signature verification")
	}

	var event OmiseWebhookEvent
	if err := json.Unmarshal(rawBody, &event); err != nil {
		return c.Status(fiber.StatusBadRequest).
			JSON(fiber.Map{"error": "invalid payload"})
	}

	if event.Key != "charge.complete" {
		return c.JSON(fiber.Map{"status": "ignored"})
	}

	if err := h.service.ConfirmPaymentFromWebhook(
		c.Context(),
		event.Data.ID,
		event.Data.Metadata,
		event.Data.Amount,
	); err != nil {
		return h.handleServiceError(c, err)
	}

	return c.JSON(fiber.Map{"status": "ok"})
}

func (h *Handler) triggerPaymentSuccess(sourceID string, bookingID uint, amount float64) {
	if h.hub == nil {
		log.Printf("⚠️  Hub not initialized, skipping WebSocket broadcast")
		return
	}

	payload := realtime.MarshalEvent("PAYMENT_SUCCESS", map[string]any{
		"source_id":  sourceID,
		"booking_id": bookingID,
		"status":     "COMPLETED",
		"amount":     amount,
	})

	go h.hub.BroadcastToAll(payload)
	log.Printf("📡 WebSocket broadcast sent: booking=%d, amount=%.2f", bookingID, amount)
}

func (h *Handler) handleServiceError(c fiber.Ctx, err error) error {
	var paymentErr *PaymentError
	if errors.As(err, &paymentErr) {
		statusCode := h.mapErrorCodeToHTTPStatus(paymentErr.Code)
		return h.respondError(c, statusCode, paymentErr.Code, paymentErr.Message, paymentErr.Err)
	}

	switch {
	case errors.Is(err, ErrInvalidPaymentID):
		return h.respondError(c, http.StatusBadRequest, "INVALID_PAYMENT_ID", err.Error(), nil)
	case errors.Is(err, ErrInvalidAmount):
		return h.respondError(c, http.StatusBadRequest, "INVALID_AMOUNT", err.Error(), nil)
	case errors.Is(err, ErrPaymentProviderUnavailable):
		return h.respondError(c, http.StatusServiceUnavailable, "PROVIDER_UNAVAILABLE", err.Error(), nil)
	default:
		return h.respondError(c, http.StatusInternalServerError, "INTERNAL_ERROR", "an internal error occurred", err)
	}
}

func (h *Handler) ConfirmPayment(c fiber.Ctx) error {
	type ConfirmRequest struct {
		BookingID uint `json:"booking_id" validate:"required"`
	}

	req := new(ConfirmRequest)
	if err := c.Bind().JSON(req); err != nil {
		return h.respondError(
			c,
			http.StatusBadRequest,
			"INVALID_REQUEST_FORMAT",
			"invalid request format",
			err,
		)
	}

	if err := h.validator.Struct(req); err != nil {
		return h.respondValidationError(c, err)
	}

	if err := h.service.ConfirmPayment(c.Context(), req.BookingID); err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "payment confirmed",
		"data": fiber.Map{
			"booking_id": req.BookingID,
			"status":     "COMPLETED",
		},
	})
}

func (h *Handler) GetPaymentHistory(c fiber.Ctx) error {
	bookingIDStr := c.Params("booking_id")

	bookingID, err := strconv.ParseUint(bookingIDStr, 10, 64)
	if err != nil {
		return h.respondError(
			c,
			http.StatusBadRequest,
			"INVALID_BOOKING_ID",
			"booking ID must be a number",
			err,
		)
	}

	history, err := h.service.GetPaymentHistory(c.Context(), uint(bookingID))
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"data":    history,
	})
}

func (h *Handler) CheckPaymentStatus(c fiber.Ctx) error {
	bookingIDStr := c.Params("booking_id")

	bookingID, err := strconv.ParseUint(bookingIDStr, 10, 64)
	if err != nil {
		return h.respondError(
			c,
			http.StatusBadRequest,
			"INVALID_BOOKING_ID",
			"booking ID must be a number",
			err,
		)
	}

	hasPaid, err := h.service.HasSuccessfulPayment(c.Context(), uint(bookingID))
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success":  true,
		"has_paid": hasPaid,
		"data": fiber.Map{
			"booking_id": bookingID,
			"status":     map[bool]string{true: "paid", false: "unpaid"}[hasPaid],
		},
	})
}

func (h *Handler) respondValidationError(c fiber.Ctx, err error) error {
	validationErrors, ok := err.(validator.ValidationErrors)
	if !ok {
		return h.respondError(c, http.StatusBadRequest, "VALIDATION_ERROR", "validation failed", err)
	}

	details := make(map[string]string)
	for _, fieldErr := range validationErrors {
		details[fieldErr.Field()] = h.formatValidationError(fieldErr)
	}

	return c.Status(http.StatusBadRequest).JSON(fiber.Map{
		"code":    "VALIDATION_ERROR",
		"message": "request validation failed",
		"details": details,
	})
}

func (h *Handler) respondError(c fiber.Ctx, statusCode int, code, message string, err error) error {
	response := ErrorResponse{
		Code:    code,
		Message: message,
	}

	return c.Status(statusCode).JSON(response)
}

