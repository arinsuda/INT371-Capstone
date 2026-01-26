package technicianbooking

import (
	"context"
	"errors"
	"time"

	appErrors "changsure-core-service/internal/errors"
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

func (h *Handler) AcceptBooking(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	bookingID, err := utils.ParseUintParam(c, "id")
	if err != nil || bookingID == 0 {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	bkg, err := h.service.AcceptBooking(c.Context(), techID, bookingID)
	if err != nil {
		switch {
		case errors.Is(err, ErrBookingNotFound):
			return appErrors.NotFound(c, "booking not found")
		case errors.Is(err, ErrForbiddenBooking):
			return appErrors.Forbidden(c, "forbidden")
		case errors.Is(err, ErrInvalidBookingStatus):
			return appErrors.Conflict(c, "invalid booking status")
		default:
			return appErrors.InternalError(c, "failed to accept booking", err)
		}
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)

	if h.hub != nil && bkg.CustomerID != 0 {
		payload := realtime.MarshalEvent("BOOKING_ACCEPTED", map[string]any{
			"booking_id":       bkg.ID,
			"status":           bkg.Status,
			"technician_id":    bkg.TechnicianID,
			"appointment_date": bkg.AppointmentDate.Format("2006-01-02"),
		})
		go h.hub.BroadcastToCustomer(bkg.CustomerID, payload)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "รับงานสำเร็จ",
		"data":    bkg,
	})
}

func (h *Handler) RejectBooking(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	bookingID, err := utils.ParseUintParam(c, "id")
	if err != nil || bookingID == 0 {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	var req RejectBookingRequest
	_ = c.Bind().Body(&req)

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	bkg, err := h.service.RejectBooking(c.Context(), techID, bookingID, req.Reason)
	if err != nil {
		switch {
		case errors.Is(err, ErrBookingNotFound):
			return appErrors.NotFound(c, "booking not found")
		case errors.Is(err, ErrForbiddenBooking):
			return appErrors.Forbidden(c, "forbidden")
		case errors.Is(err, ErrInvalidBookingStatus):
			return appErrors.Conflict(c, "invalid booking status")
		default:
			return appErrors.InternalError(c, "failed to reject booking", err)
		}
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)

	if h.hub != nil && bkg.CustomerID != 0 {
		payload := realtime.MarshalEvent("BOOKING_REJECTED", map[string]any{
			"booking_id":       bkg.ID,
			"status":           bkg.Status,
			"reason":           req.Reason,
			"technician_id":    bkg.TechnicianID,
			"appointment_date": bkg.AppointmentDate.Format("2006-01-02"),
		})
		go h.hub.BroadcastToCustomer(bkg.CustomerID, payload)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "ปฏิเสธงานสำเร็จ",
		"data":    bkg,
	})
}

func (h *Handler) ListBookings(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var q ListBookingsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "Invalid query parameters")
	}

	if details, err := validation.ValidateStruct(q); err != nil {
		return appErrors.ValidationError(c, details)
	}

	items, total, page, limit, err := h.service.ListBookings(c.Context(), techID, q)
	if err != nil {
		return appErrors.BadRequest(c, err.Error())
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

func (h *Handler) hydrateBookingMediaURLs(ctx context.Context, b *booking.Booking) {
	if b == nil || h.storage == nil {
		return
	}

	ttl := 24 * time.Hour

	if len(b.Images) > 0 {
		for i := range b.Images {
			key := b.Images[i].ImageURL
			if key == "" {
				continue
			}
			url, err := h.storage.PresignGet(ctx, key, ttl, false)
			if err == nil {
				b.Images[i].ImageURL = url
			}
		}
	}

	if b.Technician.AvatarURL != nil && *b.Technician.AvatarURL != "" {
		key := *b.Technician.AvatarURL
		url, err := h.storage.PresignGet(ctx, key, ttl, false)
		if err == nil {
			*b.Technician.AvatarURL = url
		}
	}

	if b.TechnicianService.Service.ImageURLs != nil && len(b.TechnicianService.Service.ImageURLs) > 0 {
		for i := range b.TechnicianService.Service.ImageURLs {
			key := b.TechnicianService.Service.ImageURLs[i]
			if key == "" {
				continue
			}
			url, err := h.storage.PresignGet(ctx, key, ttl, false)
			if err == nil {
				b.TechnicianService.Service.ImageURLs[i] = url
			}
		}
	}
}

func (h *Handler) StartJob(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	bookingID, err := utils.ParseUintParam(c, "id")
	if err != nil || bookingID == 0 {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	bkg, err := h.service.StartJob(c.Context(), techID, bookingID)
	if err != nil {
		return h.handleError(c, err)
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)
	h.broadcastToCustomer(bkg, "JOB_STARTED")

	return c.JSON(fiber.Map{"success": true, "message": "เริ่มปฏิบัติงาน", "data": bkg})
}

func (h *Handler) CompleteJob(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	bookingID, err := utils.ParseUintParam(c, "id")
	if err != nil || bookingID == 0 {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	bkg, err := h.service.CompleteJob(c.Context(), techID, bookingID)
	if err != nil {
		return h.handleError(c, err)
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)
	h.broadcastToCustomer(bkg, "JOB_COMPLETED")

	return c.JSON(fiber.Map{"success": true, "message": "แจ้งงานเสร็จสิ้น", "data": bkg})
}

func (h *Handler) handleError(c fiber.Ctx, err error) error {
	switch {
	case errors.Is(err, ErrBookingNotFound):
		return appErrors.NotFound(c, "booking not found")
	case errors.Is(err, ErrForbiddenBooking):
		return appErrors.Forbidden(c, "forbidden")
	case errors.Is(err, ErrInvalidBookingStatus):
		return appErrors.Conflict(c, "invalid booking status transition")
	default:
		return appErrors.InternalError(c, "failed to update booking status", err)
	}
}

func (h *Handler) broadcastToCustomer(bkg *booking.Booking, eventType string) {
	if h.hub != nil && bkg.CustomerID != 0 {
		payload := realtime.MarshalEvent(eventType, map[string]any{
			"booking_id":       bkg.ID,
			"status":           bkg.Status,
			"technician_id":    bkg.TechnicianID,
			"appointment_date": bkg.AppointmentDate.Format("2006-01-02"),
		})
		go h.hub.BroadcastToCustomer(bkg.CustomerID, payload)
	}
}
