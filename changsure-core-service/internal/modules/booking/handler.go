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
		go func(b *Booking) {
			payloadData := map[string]any{
				"booking_id":       b.ID,
				"appointment_date": b.AppointmentDate.Format("2006-01-02"),
				"time_slot":        b.TimeSlot.StartTime + " - " + b.TimeSlot.EndTime,
				"price":            b.PriceAmount,
				"service_name":     b.TechnicianService.Service.SerName,
			}

			if b.TechnicianService.Service.SerName != "" {
				payloadData["service_name"] = b.TechnicianService.Service.SerName
			}

			payload := realtime.MarshalEvent("BOOKING_CREATED", payloadData)
			h.hub.BroadcastToTechnician(b.TechnicianID, payload)

		}(result)
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

func (h *Handler) hydrateBookingMediaURLs(ctx context.Context, b *Booking) {
	if b == nil {
		return
	}

	ttl := 24 * time.Hour // ปรับได้

	// 1) booking images
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

	// 2) technician avatar
	// (avatar_url อยู่ใน b.Technician ซึ่งเป็น struct ไม่ใช่ pointer)
	if b.Technician.AvatarURL != nil && *b.Technician.AvatarURL != "" {
		key := *b.Technician.AvatarURL
		url, err := h.storage.PresignGet(ctx, key, ttl, false)
		if err == nil {
			*b.Technician.AvatarURL = url
		}
	}

	// 3) service image_urls
	// b.TechnicianService.Service.ImageURLs เป็น []string
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
