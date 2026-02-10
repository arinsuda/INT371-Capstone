package customerbooking

import (
	"context"
	"errors"
	"fmt"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/modules/booking"
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
			"technician_id":    result.TechnicianID,
			"pricing_type":     result.PricingType,
		}

		if result.PricingType == "FIXED" && result.QuotedPriceFixed != nil {
			payloadData["price"] = *result.QuotedPriceFixed
		} else if result.PricingType == "RANGE" {
			payloadData["price_min"] = result.QuotedPriceMin
			payloadData["price_max"] = result.QuotedPriceMax
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

	bkg, err := h.service.GetBookingDetail(c.Context(), uint(id))
	if err != nil {
		return appErrors.NotFound(c, "booking not found")
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)

	return c.JSON(fiber.Map{"success": true, "data": bkg})
}

func (h *Handler) CancelBooking(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	if custID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	bookingID, err := utils.ParseUintParam(c, "id")
	if err != nil || bookingID == 0 {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	var req CancelBookingRequest
	_ = c.Bind().Body(&req)

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	bkg, err := h.service.CancelBooking(c.Context(), custID, bookingID, req.Reason)
	if err != nil {
		switch {
		case errors.Is(err, ErrBookingNotFound):
			return appErrors.NotFound(c, "ไม่พบข้อมูลการจอง")
		case errors.Is(err, ErrForbiddenBooking):
			return appErrors.Forbidden(c, "คุณไม่มีสิทธิ์ยกเลิกรายการนี้")
		case errors.Is(err, ErrBookingIsStartedOrCompleted):
			return appErrors.Conflict(c, "ไม่สามารถยกเลิกรายการนี้ได้ (สถานะไม่ถูกต้อง)")
		default:
			return appErrors.InternalError(c, "ไม่สามารถยกเลิกการจองได้", err)
		}
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)

	if h.hub != nil && bkg.TechnicianID != 0 {
		payload := realtime.MarshalEvent("BOOKING_CANCELLED", map[string]any{
			"booking_id":       bkg.ID,
			"status":           bkg.Status,
			"reason":           req.Reason,
			"customer_id":      bkg.CustomerID,
			"appointment_date": bkg.AppointmentDate.Format("2006-01-02"),
		})
		go h.hub.BroadcastToTechnician(bkg.TechnicianID, payload)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "ยกเลิกการจองสำเร็จ",
		"data":    bkg,
	})
}

func (h *Handler) ListBookings(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	if custID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var q ListBookingsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "Invalid query parameters")
	}

	if details, err := validation.ValidateStruct(q); err != nil {
		return appErrors.ValidationError(c, details)
	}

	items, total, page, limit, err := h.service.ListBookings(c.Context(), custID, q)
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

			if key == "" || strings.HasPrefix(key, "http") {
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

		if !strings.HasPrefix(key, "http") {
			url, err := h.storage.PresignGet(ctx, key, ttl, false)
			if err == nil {
				*b.Technician.AvatarURL = url
			}
		}
	}

	if b.Customer.AvatarURL != nil && *b.Customer.AvatarURL != "" {
		key := *b.Customer.AvatarURL
		if !strings.HasPrefix(key, "http") {
			url, err := h.storage.PresignGet(ctx, key, ttl, false)
			if err == nil {
				*b.Customer.AvatarURL = url
			}
		}
	}

	if b.TechnicianService.Service.ImageURLs != nil {
		for i, key := range b.TechnicianService.Service.ImageURLs {
			if key == "" || strings.HasPrefix(key, "http") {
				continue
			}
			url, err := h.storage.PresignGet(ctx, key, ttl, false)
			if err == nil {
				b.TechnicianService.Service.ImageURLs[i] = url
			}
		}
	}
}
