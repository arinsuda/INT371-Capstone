package customerbooking

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"path/filepath"
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
	"github.com/google/uuid"
)

type Handler struct {
	service Service
	storage storage.Storage
	hub     *realtime.Hub
	logger  *slog.Logger
}

func NewHandler(service Service, s storage.Storage, hub *realtime.Hub, logger *slog.Logger) *Handler {
	if logger == nil {
		logger = slog.Default()
	}
	return &Handler{service: service, storage: s, hub: hub, logger: logger}
}

func (h *Handler) CreateBooking(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var req CreateBookingRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if form, err := c.MultipartForm(); err == nil && form.File != nil {
		for _, fh := range form.File["images"] {
			file, err := fh.Open()
			if err != nil {
				h.logger.Warn("failed to open booking image", "error", err)
				continue
			}
			key, err := h.storage.UploadFile(
				c.Context(),
				file,
				fmt.Sprintf("%s%s", uuid.New().String(), filepath.Ext(fh.Filename)),
				fmt.Sprintf("bookings/%s", time.Now().Format("2006/01")),
				fh.Size,
				fh.Header.Get("Content-Type"),
			)
			file.Close()
			if err != nil {
				h.logger.Warn("failed to upload booking image", "error", err)
				continue
			}
			req.ImageURLs = append(req.ImageURLs, key)
		}
	}

	req.CustomerID = customerID

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	result, err := h.service.CreateBooking(ctx, customerID, req)
	if err != nil {
		return h.mapBookingError(c, err)
	}

	h.hydrateBookingMediaURLs(c.Context(), result)
	h.broadcastBookingCreated(result)

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "จองบริการสำเร็จ",
		"data":    result,
	})
}

func (h *Handler) ListBookings(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var q ListBookingsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query parameters")
	}
	if details, err := validation.ValidateStruct(q); err != nil {
		return appErrors.ValidationError(c, details)
	}

	items, total, page, limit, err := h.service.ListBookings(c.Context(), customerID, q)
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
			"meta":  fiber.Map{"page": page, "limit": limit, "total": total},
		},
	})
}

func (h *Handler) CheckAvailability(c fiber.Ctx) error {
	var q CheckAvailabilityQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query parameters")
	}
	if details, err := validation.ValidateStruct(q); err != nil {
		return appErrors.ValidationError(c, details)
	}

	slots, err := h.service.GetAvailableTimeSlots(c.Context(), q.TechnicianID, q.Date)
	if err != nil {
		if errors.Is(err, ErrInvalidDateFormat) {
			return appErrors.BadRequest(c, "รูปแบบวันที่ไม่ถูกต้อง (ต้องเป็น YYYY-MM-DD)")
		}
		return appErrors.InternalError(c, "failed to fetch availability", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": slots})
}

func (h *Handler) GetBookingDetail(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	bookingID, err := utils.ParseUintParam(c, "bookingID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	bkg, err := h.service.GetBookingDetail(c.Context(), bookingID)
	if err != nil || bkg == nil {
		return appErrors.NotFound(c, "ไม่พบข้อมูลการจอง")
	}

	if bkg.CustomerID != customerID && !middleware.IsAdmin(c) {
		return appErrors.Forbidden(c, "คุณไม่มีสิทธิ์เข้าถึงรายการนี้")
	}

	h.hydrateBookingMediaURLs(c.Context(), bkg)
	return c.JSON(fiber.Map{"success": true, "data": bkg})
}

func (h *Handler) UpdateBooking(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	bookingID, err := utils.ParseUintParam(c, "bookingID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid booking id")
	}

	var req UpdateBookingRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	switch req.Status {

	case "cancelled":
		bkg, err := h.service.CancelBooking(c.Context(), customerID, bookingID, req.Reason)
		if err != nil {
			return h.mapBookingError(c, err)
		}

		h.hydrateBookingMediaURLs(c.Context(), bkg)
		h.broadcastBookingCancelled(bkg, req.Reason)

		return c.JSON(fiber.Map{
			"success": true,
			"message": "ยกเลิกการจองสำเร็จ",
			"data":    bkg,
		})

	default:
		return appErrors.BadRequest(c, "unsupported update operation")
	}
}

func (h *Handler) mapBookingError(c fiber.Ctx, err error) error {
	switch {
	case errors.Is(err, ErrSlotBooked):
		return appErrors.Conflict(c, "ช่วงเวลานี้ถูกจองเต็มแล้ว")
	case errors.Is(err, ErrServiceNotFound):
		return appErrors.NotFound(c, "ไม่พบบริการที่เลือก")
	case errors.Is(err, ErrTechnicianDoesNotHaveService):
		return appErrors.BadRequest(c, "ช่างไม่มีบริการนี้ในรายการ")
	case errors.Is(err, ErrAddressNotFound):
		return appErrors.BadRequest(c, "ที่อยู่ไม่ถูกต้องหรือไม่มีสิทธิ์ใช้งาน")
	case errors.Is(err, ErrInvalidDateFormat):
		return appErrors.BadRequest(c, "รูปแบบวันที่ไม่ถูกต้อง (ต้องเป็น YYYY-MM-DD)")
	case errors.Is(err, ErrTechnicianClosed):
		return appErrors.BadRequest(c, "ช่างปิดรับงานในวันที่เลือก")
	case errors.Is(err, ErrInvalidTimeSlot):
		return appErrors.BadRequest(c, "ช่วงเวลาไม่ถูกต้องหรือมีการเปลี่ยนแปลง กรุณาเลือกใหม่")
	case errors.Is(err, ErrServiceAreaNotCovered):
		return appErrors.BadRequest(c, "ช่างไม่ให้บริการในพื้นที่นี้")
	case errors.Is(err, ErrBookingNotFound):
		return appErrors.NotFound(c, "ไม่พบข้อมูลการจอง")
	case errors.Is(err, ErrForbiddenBooking):
		return appErrors.Forbidden(c, "คุณไม่มีสิทธิ์เข้าถึงรายการนี้")
	case errors.Is(err, ErrBookingIsStartedOrCompleted):
		return appErrors.Conflict(c, "ไม่สามารถยกเลิกรายการที่กำลังดำเนินการหรือเสร็จสิ้นแล้ว")
	case errors.Is(err, ErrTechnicianBanned):
		return appErrors.Forbidden(c, "ช่างคนนี้ถูกระงับการใช้งานชั่วคราว ไม่สามารถจองได้")
	default:
		return appErrors.InternalError(c, "ไม่สามารถทำรายการได้", err)
	}
}

func (h *Handler) broadcastBookingCreated(result *booking.Booking) {
	if h.hub == nil || result == nil {
		return
	}

	payload := map[string]any{
		"booking_id":       result.ID,
		"booking_number":   result.BookingNumber,
		"customer_id":      result.CustomerID,
		"technician_id":    result.TechnicianID,
		"status":           result.Status,
		"appointment_date": result.AppointmentDate.Format("2006-01-02"),
		"pricing_type":     result.PricingType,
	}

	if result.PricingType == "FIXED" && result.QuotedPriceFixed != nil {
		payload["price"] = *result.QuotedPriceFixed
	} else {
		payload["price_min"] = result.QuotedPriceMin
		payload["price_max"] = result.QuotedPriceMax
	}

	if result.TimeSlot.ID != 0 {
		payload["time_slot"] = map[string]any{
			"id":         result.TimeSlot.ID,
			"start_time": result.TimeSlot.StartTime,
			"end_time":   result.TimeSlot.EndTime,
			"label":      result.TimeSlot.StartTime + " - " + result.TimeSlot.EndTime,
		}
	}

	if result.TechnicianService.Service.ID != 0 {
		payload["service"] = map[string]any{
			"id":   result.TechnicianService.Service.ID,
			"name": result.TechnicianService.Service.SerName,
		}
		if result.TechnicianService.Service.Category.ID != 0 {
			payload["service_category"] = result.TechnicianService.Service.Category.CatName
		}
	}

	go h.hub.BroadcastToTechnician(result.TechnicianID, realtime.MarshalEvent(realtime.EventBookingCreated, payload))
}

func (h *Handler) broadcastBookingCancelled(bkg *booking.Booking, reason string) {
	if h.hub == nil || bkg == nil || bkg.TechnicianID == 0 {
		return
	}
	go h.hub.BroadcastToTechnician(bkg.TechnicianID, realtime.MarshalEvent("BOOKING_CANCELLED", map[string]any{
		"booking_id":       bkg.ID,
		"status":           bkg.Status,
		"reason":           reason,
		"customer_id":      bkg.CustomerID,
		"appointment_date": bkg.AppointmentDate.Format("2006-01-02"),
	}))
}

func (h *Handler) hydrateBookingMediaURLs(ctx context.Context, b *booking.Booking) {
	if b == nil || h.storage == nil {
		return
	}

	const ttl = 24 * time.Hour

	for i := range b.Images {
		if key := b.Images[i].ImageURL; key != "" && !strings.HasPrefix(key, "http") {
			if url, err := h.storage.PresignGet(ctx, key, ttl, false); err == nil {
				b.Images[i].ImageURL = url
			}
		}
	}

	presignPtr := func(p **string) {
		if *p == nil || **p == "" || strings.HasPrefix(**p, "http") {
			return
		}
		if url, err := h.storage.PresignGet(ctx, **p, ttl, false); err == nil {
			*p = &url
		}
	}

	presignPtr(&b.Technician.AvatarURL)
	presignPtr(&b.Customer.AvatarURL)

	for i, key := range b.TechnicianService.Service.ImageURLs {
		if key != "" && !strings.HasPrefix(key, "http") {
			if url, err := h.storage.PresignGet(ctx, key, ttl, false); err == nil {
				b.TechnicianService.Service.ImageURLs[i] = url
			}
		}
	}
}
