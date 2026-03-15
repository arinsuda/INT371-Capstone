package payment

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v3"

	"changsure-core-service/internal/realtime"
)

type Handler struct {
	service       Service
	hub           *realtime.Hub
	validator     *validator.Validate
	isTestMode    bool
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

func (h *Handler) ConfirmPayment(c fiber.Ctx) error {
	type ConfirmRequest struct {
		BookingID uint `json:"booking_id" validate:"required"`
	}
	req := new(ConfirmRequest)
	if err := c.Bind().JSON(req); err != nil {
		return h.respondError(c, http.StatusBadRequest, "INVALID_REQUEST_FORMAT", "invalid request format", err)
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
		"data":    fiber.Map{"booking_id": req.BookingID, "status": "COMPLETED"},
	})
}

func (h *Handler) GetPaymentHistory(c fiber.Ctx) error {
	bookingID, err := strconv.ParseUint(c.Params("booking_id"), 10, 64)
	if err != nil {
		return h.respondError(c, http.StatusBadRequest, "INVALID_BOOKING_ID", "booking ID must be a number", err)
	}
	history, err := h.service.GetPaymentHistory(c.Context(), uint(bookingID))
	if err != nil {
		return h.handleServiceError(c, err)
	}
	return c.Status(http.StatusOK).JSON(fiber.Map{"success": true, "data": history})
}

func (h *Handler) CheckPaymentStatus(c fiber.Ctx) error {
	bookingID, err := strconv.ParseUint(c.Params("booking_id"), 10, 64)
	if err != nil {
		return h.respondError(c, http.StatusBadRequest, "INVALID_BOOKING_ID", "booking ID must be a number", err)
	}
	hasPaid, err := h.service.HasSuccessfulPayment(c.Context(), uint(bookingID))
	if err != nil {
		return h.handleServiceError(c, err)
	}
	status := "unpaid"
	if hasPaid {
		status = "paid"
	}
	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success":  true,
		"has_paid": hasPaid,
		"data":     fiber.Map{"booking_id": bookingID, "status": status},
	})
}

func (h *Handler) OmiseWebhook(c fiber.Ctx) error {
	rawBody := c.Request().Body()

	os.WriteFile("/tmp/webhook_body.json", rawBody, 0644)

	rawSig := string(c.Request().Header.Peek("Omise-Signature"))
	log.Printf("🔍 Body bytes (first 100): %v", rawBody[:min(100, len(rawBody))])
	log.Printf("🔍 Body as string: [%s]", string(rawBody[:min(200, len(rawBody))]))
	log.Printf("🔍 Raw Omise-Signature: '%s'", rawSig)
	log.Printf("🔍 Body length: %d", len(rawBody))
	log.Printf("🔍 Body: %s", string(rawBody))

	if h.webhookSecret == "" {
		log.Printf("❌ Webhook secret is not configured — rejecting request")
		return c.Status(fiber.StatusInternalServerError).
			JSON(fiber.Map{"error": "webhook secret not configured"})
	}

	if rawSig == "" {
		return c.Status(fiber.StatusUnauthorized).
			JSON(fiber.Map{"error": "missing signature"})
	}

	if !VerifyOmiseSignature(rawBody, rawSig, h.webhookSecret) {
		return c.Status(fiber.StatusUnauthorized).
			JSON(fiber.Map{"error": "invalid signature"})
	}

	log.Printf("✅ Webhook signature verified")

	var event OmiseWebhookEvent
	if err := json.Unmarshal(rawBody, &event); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid payload"})
	}

	switch event.Key {
	case "charge.complete":
		if event.Data.Status == "failed" {
			if err := h.service.HandleFailedPayment(
				c.Context(),
				event.Data.ID,
				event.Data.Metadata,
			); err != nil {
				log.Printf("[ERROR] HandleFailedPayment: %v", err)
			}
			go h.broadcastFromMetadata(event.Data.Metadata, func(customerID, technicianID uint) {
				payload := realtime.MarshalEvent(realtime.EventPaymentFailed, map[string]any{
					"charge_id":  event.Data.ID,
					"booking_id": metadataBookingIDStr(event.Data.Metadata),
					"status":     "failed",
				})
				if customerID != 0 {
					h.hub.BroadcastToCustomer(customerID, payload)
				}
				if technicianID != 0 {
					h.hub.BroadcastToTechnician(technicianID, payload)
				}
			})
		} else {
			if err := h.service.ConfirmPaymentFromWebhook(
				c.Context(),
				event.Data.ID,
				event.Data.Metadata,
				event.Data.Amount,
			); err != nil {
				log.Printf("[ERROR] ConfirmPaymentFromWebhook: %v", err)
				return h.handleServiceError(c, err)
			}
			go h.broadcastFromMetadata(event.Data.Metadata, func(customerID, technicianID uint) {
				payload := realtime.MarshalEvent(realtime.EventPaymentSuccess, map[string]any{
					"source_id": event.Data.ID,
					"amount":    float64(event.Data.Amount) / 100,
					"status":    "COMPLETED",
				})
				if customerID != 0 {
					h.hub.BroadcastToCustomer(customerID, payload)
				}
				if technicianID != 0 {
					h.hub.BroadcastToTechnician(technicianID, payload)
				}
			})
		}

	default:
		return c.JSON(fiber.Map{"status": "ignored", "key": event.Key})
	}

	return c.JSON(fiber.Map{"status": "ok"})
}

func (h *Handler) SimulatePaymentSuccess(c fiber.Ctx) error {
	if !h.isTestMode {
		return h.respondError(c, http.StatusForbidden, "NOT_ALLOWED", "simulation only available in test mode", nil)
	}

	type SimulateRequest struct {
		SourceID  string  `json:"source_id"  validate:"required"`
		BookingID uint    `json:"booking_id" validate:"required"`
		Amount    float64 `json:"amount"     validate:"required,gt=0"`
	}
	req := new(SimulateRequest)
	if err := c.Bind().JSON(req); err != nil {
		return h.respondError(c, 400, "INVALID_REQUEST", "invalid format", err)
	}
	if err := h.validator.Struct(req); err != nil {
		return h.respondValidationError(c, err)
	}

	chargeID := fmt.Sprintf("sim_%s_%d", req.SourceID, req.BookingID)
	metadata := map[string]interface{}{
		"booking_id": strconv.Itoa(int(req.BookingID)),
	}

	if err := h.service.ConfirmPaymentFromWebhook(
		c.Context(),
		chargeID,
		metadata,
		int64(req.Amount*100),
	); err != nil {
		return h.handleServiceError(c, err)
	}

	go h.broadcastFromMetadata(metadata, func(customerID, technicianID uint) {
		payload := realtime.MarshalEvent(realtime.EventPaymentSuccess, map[string]any{
			"source_id": req.SourceID,
			"amount":    req.Amount,
			"status":    "COMPLETED",
		})
		if customerID != 0 {
			h.hub.BroadcastToCustomer(customerID, payload)
		}
		if technicianID != 0 {
			h.hub.BroadcastToTechnician(technicianID, payload)
		}
	})

	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "payment success simulated",
		"data": fiber.Map{
			"booking_id": req.BookingID,
			"charge_id":  chargeID,
			"amount":     req.Amount,
		},
	})
}

func (h *Handler) broadcastFromMetadata(
	metadata map[string]interface{},
	fn func(customerID, technicianID uint),
) {
	if h.hub == nil {
		return
	}

	rawID, ok := metadata["booking_id"]
	if !ok {
		log.Printf("[WARN] broadcastFromMetadata: no booking_id in metadata, skipping broadcast")
		return
	}
	bookingIDStr, ok := rawID.(string)
	if !ok {
		log.Printf("[WARN] broadcastFromMetadata: booking_id is not string, skipping broadcast")
		return
	}
	bookingID64, err := strconv.ParseUint(bookingIDStr, 10, 64)
	if err != nil {
		log.Printf("[WARN] broadcastFromMetadata: invalid booking_id %q, skipping broadcast", bookingIDStr)
		return
	}

	bkg, err := h.service.GetBookingSummary(context.Background(), uint(bookingID64))
	if err != nil || bkg == nil {
		log.Printf("[WARN] broadcastFromMetadata: booking %d not found: %v", bookingID64, err)
		return
	}

	fn(bkg.CustomerID, bkg.TechnicianID)
}

func metadataBookingIDStr(metadata map[string]interface{}) string {
	if v, ok := metadata["booking_id"]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
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
	if err != nil && statusCode >= 500 {
		log.Printf("[ERROR] payment handler: code=%s message=%s err=%v", code, message, err)
	}
	return c.Status(statusCode).JSON(ErrorResponse{
		Code:    code,
		Message: message,
	})
}

func (h *Handler) CancelPaymentQR(c fiber.Ctx) error {
	bookingID, err := strconv.ParseUint(c.Params("booking_id"), 10, 64)
	if err != nil {
		return h.respondError(c, http.StatusBadRequest, "INVALID_BOOKING_ID", "booking ID must be a number", err)
	}
	if err := h.service.CancelPaymentQR(c.Context(), uint(bookingID)); err != nil {
		return h.handleServiceError(c, err)
	}
	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "payment cancelled",
		"data":    fiber.Map{"booking_id": bookingID, "status": PaymentStatusCancelled},
	})
}
