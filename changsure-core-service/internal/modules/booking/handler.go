package booking

import (
	"context"
	"errors"
	"fmt"
	"path/filepath"
	"strconv"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/realtime"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
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

func (h *Handler) CreateBooking(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	if custID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req CreateBookingRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	form, err := c.MultipartForm()
	if err == nil && form.File != nil {

		files := form.File["images"]

		for _, fileHeader := range files {
			file, err := fileHeader.Open()
			if err != nil {
				continue
			}

			ext := filepath.Ext(fileHeader.Filename)
			fileName := fmt.Sprintf("%s%s", uuid.New().String(), ext)
			folder := fmt.Sprintf("bookings/%s", time.Now().Format("2006/01"))

			key, err := h.storage.UploadFile(
				c.Context(),
				file,
				fileName,
				folder,
				fileHeader.Size,
				fileHeader.Header.Get("Content-Type"),
			)

			file.Close()

			if err != nil {
				fmt.Printf("Failed to upload image: %v\n", err)
				continue
			}

			req.ImageURLs = append(req.ImageURLs, key)
		}
	}

	req.CustomerID = custID

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	result, err := h.service.CreateBooking(ctx, custID, req)

	if err != nil {
		switch {
		case errors.Is(err, ErrSlotBooked):
			return appErrors.Conflict(c, "ช่วงเวลานี้ถูกจองเต็มแล้ว")
		case errors.Is(err, ErrServiceNotFound):
			return appErrors.NotFound(c, "ไม่พบบริการที่เลือก")
		case errors.Is(err, ErrAddressNotFound):
			return appErrors.BadRequest(c, "ที่อยู่ไม่ถูกต้องหรือไม่มีสิทธิ์ใช้งาน")
		case errors.Is(err, ErrInvalidDateFormat):
			return appErrors.BadRequest(c, "รูปแบบวันที่ไม่ถูกต้อง (ต้องเป็น YYYY-MM-DD)")
		case errors.Is(err, ErrTechnicianClosed):
			return appErrors.BadRequest(c, "ช่างปิดรับงานในวันที่เลือก")
		case errors.Is(err, ErrInvalidTimeSlot):
			return appErrors.BadRequest(c, "ช่วงเวลาไม่ถูกต้องหรือมีการเปลี่ยนแปลง กรุณาเลือกใหม่")
		default:
			return appErrors.InternalError(c, "ไม่สามารถทำรายการได้", err)
		}
	}

	h.hydrateBookingMediaURLs(c.Context(), result)

	if h.hub != nil {
		payloadData := map[string]any{
			"booking_id":       result.ID,
			"appointment_date": result.AppointmentDate.Format("2006-01-02"),
			"price":            result.PriceAmount,
			"technician_id":    result.TechnicianID,
		}

		if result.TimeSlot.ID != 0 && result.TimeSlot.StartTime != "" {
			payloadData["time_slot"] = result.TimeSlot.StartTime + " - " + result.TimeSlot.EndTime
		}

		if result.TechnicianService.ID != 0 && result.TechnicianService.Service.ID != 0 {
			if result.TechnicianService.Service.SerName != "" {
				payloadData["service_name"] = result.TechnicianService.Service.SerName
			}
		}

		payload := realtime.MarshalEvent("BOOKING_CREATED", payloadData)

		go h.hub.BroadcastToTechnician(result.TechnicianID, payload)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "จองบริการสำเร็จ",
		"data":    result,
	})
}

func (h *Handler) CheckAvailability(c fiber.Ctx) error {
	var query CheckAvailabilityQuery

	if err := c.Bind().Query(&query); err != nil {
		return appErrors.BadRequest(c, "Invalid query parameters")
	}

	slots, err := h.service.GetAvailableTimeSlots(c.Context(), query.TechnicianID, query.Date)
	if err != nil {
		if errors.Is(err, ErrInvalidDateFormat) {
			return appErrors.BadRequest(c, "รูปแบบวันที่ไม่ถูกต้อง (ต้องเป็น YYYY-MM-DD)")
		}
		return appErrors.InternalError(c, "failed to fetch availability", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": slots})
}

func (h *Handler) GetBookingDetail(c fiber.Ctx) error {
	idStr := c.Params("id")
	id, err := strconv.ParseUint(idStr, 10, 32)
	if err != nil {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	booking, err := h.service.GetBookingDetail(c.Context(), uint(id))
	if err != nil {
		return appErrors.NotFound(c, "booking not found")
	}

	h.hydrateBookingMediaURLs(c.Context(), booking)

	return c.JSON(fiber.Map{"success": true, "data": booking})
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

	booking, err := h.service.AcceptBooking(c.Context(), techID, bookingID)
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

	h.hydrateBookingMediaURLs(c.Context(), booking)

	if h.hub != nil && booking.CustomerID != 0 {
		payload := realtime.MarshalEvent("BOOKING_ACCEPTED", map[string]any{
			"booking_id":       booking.ID,
			"status":           booking.Status,
			"technician_id":    booking.TechnicianID,
			"appointment_date": booking.AppointmentDate.Format("2006-01-02"),
		})
		go h.hub.BroadcastToCustomer(booking.CustomerID, payload)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "รับงานสำเร็จ",
		"data":    booking,
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
	_ = c.Bind().Body(&req) // reason optional

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	booking, err := h.service.RejectBooking(c.Context(), techID, bookingID, req.Reason)
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

	h.hydrateBookingMediaURLs(c.Context(), booking)

	if h.hub != nil && booking.CustomerID != 0 {
		payload := realtime.MarshalEvent("BOOKING_REJECTED", map[string]any{
			"booking_id":       booking.ID,
			"status":           booking.Status,
			"reason":           req.Reason,
			"technician_id":    booking.TechnicianID,
			"appointment_date": booking.AppointmentDate.Format("2006-01-02"),
		})
		go h.hub.BroadcastToCustomer(booking.CustomerID, payload)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "ปฏิเสธงานสำเร็จ",
		"data":    booking,
	})
}

func (h *Handler) ListTechnicianBookings(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var q ListTechnicianBookingsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "Invalid query parameters")
	}

	if details, err := validation.ValidateStruct(q); err != nil {
		return appErrors.ValidationError(c, details)
	}

	items, total, page, limit, err := h.service.ListTechnicianBookings(c.Context(), techID, q)
	if err != nil {
		return appErrors.InternalError(c, "failed to fetch bookings", err)
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

func (h *Handler) hydrateBookingMediaURLs(ctx context.Context, b *Booking) {
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
