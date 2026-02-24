package technicianbooking

import (
	"context"
	"errors"
	"strings"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/realtime"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
	storage storage.Storage
	hub     *realtime.Hub
}

func NewHandler(service Service, s storage.Storage, hub *realtime.Hub) *Handler {
	return &Handler{
		service: service,
		storage: s,
		hub:     hub,
	}
}

// parseTechID ดึง technicianID จาก path param และเช็ค ownership
func (h *Handler) parseTechID(c fiber.Ctx) (uint, error) {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return 0, err
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return 0, err
	}
	return techID, nil
}

// GET /:technicianID/bookings
func (h *Handler) ListBookings(c fiber.Ctx) error {
	techID, err := h.parseTechID(c)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	var q ListBookingsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query parameters")
	}

	if details, err := validation.ValidateStruct(q); err != nil {
		return appErrors.ValidationError(c, details)
	}

	items, total, page, limit, err := h.service.ListBookings(c.Context(), techID, q)
	if err != nil {
		return h.handleError(c, err)
	}

	for i := range items {
		h.hydrateBookingMediaURLs(c.Context(), &items[i])
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items": items,
			"meta": fiber.Map{
				"page":  page,
				"limit": limit,
				"total": total,
			},
		},
	})
}

// GET /:technicianID/bookings/:bookingID
func (h *Handler) GetBooking(c fiber.Ctx) error {
	techID, err := h.parseTechID(c)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	bookingID, err := utils.ParseUintParam(c, "bookingID")
	if err != nil || bookingID == 0 {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	bkg, err := h.service.GetBookingByID(c.Context(), techID, bookingID)
	if err != nil {
		return h.handleError(c, err)
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)

	return c.JSON(fiber.Map{
		"success": true,
		"data":    bkg,
	})
}

// PATCH /:technicianID/bookings/:bookingID/status
// body: { action, reason? }
// action: ACCEPT | REJECT | START | COMPLETE
func (h *Handler) UpdateBookingStatus(c fiber.Ctx) error {
	techID, err := h.parseTechID(c)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	bookingID, err := utils.ParseUintParam(c, "bookingID")
	if err != nil || bookingID == 0 {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	var req UpdateBookingStatusRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	if err := req.Validate(); err != nil {
		return appErrors.BadRequest(c, err.Error())
	}

	var (
		bkg     *booking.Booking
		svcErr  error
		message string
	)

	switch req.Action {
	case "ACCEPT":
		bkg, svcErr = h.service.AcceptBooking(c.Context(), techID, bookingID)
		message = "รับงานสำเร็จ"
	case "REJECT":
		bkg, svcErr = h.service.RejectBooking(c.Context(), techID, bookingID, req.Reason)
		message = "ปฏิเสธงานสำเร็จ"
	case "START":
		bkg, svcErr = h.service.StartJob(c.Context(), techID, bookingID)
		message = "เริ่มปฏิบัติงาน"
	case "COMPLETE":
		bkg, svcErr = h.service.CompleteJob(c.Context(), techID, bookingID)
		message = "แจ้งงานเสร็จสิ้น"
	}

	if svcErr != nil {
		return h.handleError(c, svcErr)
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)
	h.broadcastEvent(bkg, req.Action, req.Reason)

	return c.JSON(fiber.Map{
		"success": true,
		"message": message,
		"data":    bkg,
	})
}

func (h *Handler) handleError(c fiber.Ctx, err error) error {
	switch {
	case errors.Is(err, ErrTechnicianNotFound):
		return appErrors.NotFound(c, "technician not found")
	case errors.Is(err, ErrBookingNotFound):
		return appErrors.NotFound(c, "booking not found")
	case errors.Is(err, ErrForbiddenBooking):
		return appErrors.Forbidden(c, "forbidden")
	case errors.Is(err, ErrInvalidBookingStatus):
		return appErrors.Conflict(c, "invalid booking status transition")
	default:
		return appErrors.InternalError(c, "failed to process request", err)
	}
}

func (h *Handler) broadcastEvent(bkg *booking.Booking, action string, reason string) {
	if h.hub == nil || bkg == nil || bkg.CustomerID == 0 {
		return
	}

	base := map[string]any{
		"booking_id":       bkg.ID,
		"status":           bkg.Status,
		"technician_id":    bkg.TechnicianID,
		"appointment_date": bkg.AppointmentDate.Format("2006-01-02"),
	}

	switch action {
	case "ACCEPT":
		go h.hub.BroadcastToCustomer(bkg.CustomerID, realtime.MarshalEvent("BOOKING_ACCEPTED", base))
		chatPayload := realtime.MarshalEvent("CHAT_ROOM_UPDATED", map[string]any{
			"booking_id": bkg.ID,
			"status":     bkg.Status,
		})
		go h.hub.BroadcastToCustomer(bkg.CustomerID, chatPayload)
		go h.hub.BroadcastToTechnician(bkg.TechnicianID, chatPayload)

	case "REJECT":
		payload := map[string]any{
			"booking_id":       bkg.ID,
			"status":           bkg.Status,
			"reason":           reason,
			"technician_id":    bkg.TechnicianID,
			"appointment_date": bkg.AppointmentDate.Format("2006-01-02"),
		}
		go h.hub.BroadcastToCustomer(bkg.CustomerID, realtime.MarshalEvent("BOOKING_REJECTED", payload))

	case "START":
		go h.hub.BroadcastToCustomer(bkg.CustomerID, realtime.MarshalEvent("JOB_STARTED", base))

	case "COMPLETE":
		statusPayload := map[string]any{
			"booking_id":       bkg.ID,
			"status":           bkg.Status,
			"previous_status":  "IN_PROGRESS",
			"action":           "COMPLETED",
			"technician_id":    bkg.TechnicianID,
			"customer_id":      bkg.CustomerID,
			"appointment_date": bkg.AppointmentDate.Format("2006-01-02"),
			"can_chat":         false,
		}
		go h.hub.BroadcastToCustomer(bkg.CustomerID, realtime.MarshalEvent(realtime.EventBookingStatusChanged, statusPayload))
		go h.hub.BroadcastToTechnician(bkg.TechnicianID, realtime.MarshalEvent(realtime.EventBookingStatusChanged, statusPayload))

		lockPayload := map[string]any{
			"booking_id": bkg.ID,
			"status":     bkg.Status,
			"can_chat":   false,
			"reason":     "Job completed - waiting for payment",
		}
		go h.hub.BroadcastToCustomer(bkg.CustomerID, realtime.MarshalEvent(realtime.EventChatRoomLocked, lockPayload))
		go h.hub.BroadcastToTechnician(bkg.TechnicianID, realtime.MarshalEvent(realtime.EventChatRoomLocked, lockPayload))

		go h.hub.BroadcastToCustomer(bkg.CustomerID, realtime.MarshalEvent(realtime.EventJobCompleted, base))
	}
}

func (h *Handler) hydrateBookingMediaURLs(ctx context.Context, b *booking.Booking) {
	if b == nil || h.storage == nil {
		return
	}

	ttl := 24 * time.Hour

	for i := range b.Images {
		key := b.Images[i].ImageURL
		if key == "" || strings.HasPrefix(key, "http") {
			continue
		}
		if url, err := h.storage.PresignGet(ctx, key, ttl, false); err == nil {
			b.Images[i].ImageURL = url
		}
	}

	if b.Technician.AvatarURL != nil && *b.Technician.AvatarURL != "" {
		key := *b.Technician.AvatarURL
		if !strings.HasPrefix(key, "http") {
			if url, err := h.storage.PresignGet(ctx, key, ttl, false); err == nil {
				*b.Technician.AvatarURL = url
			}
		}
	}

	if b.Customer.AvatarURL != nil && *b.Customer.AvatarURL != "" {
		key := *b.Customer.AvatarURL
		if !strings.HasPrefix(key, "http") {
			if url, err := h.storage.PresignGet(ctx, key, ttl, false); err == nil {
				*b.Customer.AvatarURL = url
			}
		}
	}

	for i, key := range b.TechnicianService.Service.ImageURLs {
		if key == "" || strings.HasPrefix(key, "http") {
			continue
		}
		if url, err := h.storage.PresignGet(ctx, key, ttl, false); err == nil {
			b.TechnicianService.Service.ImageURLs[i] = url
		}
	}
}
