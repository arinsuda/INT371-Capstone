package payment

import (
	"context"
	"encoding/json"
	"errors"
	"log/slog"
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
	logger        *slog.Logger
}

func NewHandler(
	service Service,
	hub *realtime.Hub,
	webhookSecret string,
	isTestMode bool,
	logger *slog.Logger,
) *Handler {
	if logger == nil {
		logger = slog.Default()
	}
	return &Handler{
		service:       service,
		hub:           hub,
		validator:     validator.New(),
		isTestMode:    isTestMode,
		webhookSecret: webhookSecret,
		logger:        logger.With("handler", "payment"),
	}
}

func (h *Handler) CreatePayment(c fiber.Ctx) error {
	req := new(CreatePaymentRequest)
	if err := c.Bind().JSON(req); err != nil {
		return h.respondError(c, http.StatusBadRequest, "INVALID_REQUEST_FORMAT", "invalid format", err)
	}
	if err := h.validator.Struct(req); err != nil {
		return h.respondValidationError(c, err)
	}

	response, err := h.service.CreatePayment(c.Context(), req)
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    response,
	})
}

func (h *Handler) GetPayment(c fiber.Ctx) error {
	paymentID := c.Params("paymentID")
	if paymentID == "" {
		return h.respondError(c, http.StatusBadRequest, "INVALID_PAYMENT_ID", "payment ID is required", nil)
	}

	source, err := h.service.GetPaymentSource(c.Context(), paymentID)
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"data":    source,
	})
}

func (h *Handler) GetPaymentsByBooking(c fiber.Ctx) error {
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

func (h *Handler) GetPaymentStatusByBooking(c fiber.Ctx) error {
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

func (h *Handler) CancelPendingPayment(c fiber.Ctx) error {
	bookingID, err := strconv.ParseUint(c.Params("booking_id"), 10, 64)
	if err != nil {
		return h.respondError(c, http.StatusBadRequest, "INVALID_BOOKING_ID", "booking ID must be a number", err)
	}

	if err := h.service.CancelPaymentQR(c.Context(), uint(bookingID)); err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusNoContent).Send(nil)
}

func (h *Handler) UpdatePaymentStatus(c fiber.Ctx) error {
	type UpdateStatusRequest struct {
		BookingID uint   `json:"booking_id" validate:"required"`
		Status    string `json:"status"     validate:"required,oneof=CONFIRMED REFUNDED"`
	}

	req := new(UpdateStatusRequest)
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
		"data": fiber.Map{
			"booking_id": req.BookingID,
			"status":     req.Status,
		},
	})
}

func (h *Handler) OmiseWebhook(c fiber.Ctx) error {
	rawBody := c.Request().Body()

	if h.isTestMode {
		_ = os.WriteFile("/tmp/webhook_body.json", rawBody, 0644)
	}

	rawSig := string(c.Request().Header.Peek("Omise-Signature"))

	h.logger.Debug("webhook received",
		"body_len", len(rawBody),
		"has_sig", rawSig != "",
	)

	if h.webhookSecret != "" {
		if rawSig == "" {
			h.logger.Warn("webhook missing signature")
			return c.Status(fiber.StatusUnauthorized).
				JSON(fiber.Map{"error": "missing signature"})
		}
		if !VerifyOmiseSignature(rawBody, rawSig, h.webhookSecret) {
			h.logger.Warn("webhook invalid signature")
			return c.Status(fiber.StatusUnauthorized).
				JSON(fiber.Map{"error": "invalid signature"})
		}
		h.logger.Debug("webhook signature verified")
	} else {
		h.logger.Warn("no webhook secret configured, skipping verification")
	}

	var event OmiseWebhookEvent
	if err := json.Unmarshal(rawBody, &event); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"error": "invalid payload"})
	}

	switch event.Key {
	case "charge.complete":
		if event.Data.Status == "failed" {
			h.handleFailedCharge(c.Context(), event)
		} else {
			if err := h.handleSuccessfulCharge(c, event); err != nil {
				return err
			}
		}
	default:
		h.logger.Info("webhook ignored", "key", event.Key)
		return c.JSON(fiber.Map{"status": "ignored", "key": event.Key})
	}

	return c.JSON(fiber.Map{"status": "ok"})
}

func (h *Handler) handleFailedCharge(ctx context.Context, event OmiseWebhookEvent) {
	if err := h.service.HandleFailedPayment(ctx, event.Data.ID, event.Data.Metadata); err != nil {
		h.logger.Error("HandleFailedPayment", "charge_id", event.Data.ID, "error", err)
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
}

func (h *Handler) handleSuccessfulCharge(c fiber.Ctx, event OmiseWebhookEvent) error {
	if err := h.service.ConfirmPaymentFromWebhook(
		c.Context(),
		event.Data.ID,
		event.Data.Metadata,
		event.Data.Amount,
	); err != nil {
		h.logger.Error("ConfirmPaymentFromWebhook", "charge_id", event.Data.ID, "error", err)
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
	return nil
}

func (h *Handler) SimulatePayment(c fiber.Ctx) error {
	if !h.isTestMode {
		return h.respondError(c, http.StatusForbidden, "NOT_ALLOWED", "simulation only available in test mode", nil)
	}

	req := new(SimulatePaymentRequest)
	if err := c.Bind().JSON(req); err != nil {
		return h.respondError(c, http.StatusBadRequest, "INVALID_REQUEST", "invalid format", err)
	}
	if err := h.validator.Struct(req); err != nil {
		return h.respondValidationError(c, err)
	}

	chargeID := "sim_" + req.PaymentID + "_" + strconv.Itoa(int(req.BookingID))
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
			"source_id": req.PaymentID,
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

	return c.Status(http.StatusCreated).JSON(fiber.Map{
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
		h.logger.Warn("broadcastFromMetadata: no booking_id in metadata")
		return
	}
	bookingIDStr, ok := rawID.(string)
	if !ok {
		h.logger.Warn("broadcastFromMetadata: booking_id is not string")
		return
	}
	bookingID64, err := strconv.ParseUint(bookingIDStr, 10, 64)
	if err != nil {
		h.logger.Warn("broadcastFromMetadata: invalid booking_id", "value", bookingIDStr)
		return
	}

	bkg, err := h.service.GetBookingSummary(context.Background(), uint(bookingID64))
	if err != nil || bkg == nil {
		h.logger.Warn("broadcastFromMetadata: booking not found", "booking_id", bookingID64, "error", err)
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
		h.logger.Error("unhandled payment error", "error", err)
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
		h.logger.Error("payment error", "code", code, "message", message, "error", err)
	}
	return c.Status(statusCode).JSON(ErrorResponse{Code: code, Message: message})
}
