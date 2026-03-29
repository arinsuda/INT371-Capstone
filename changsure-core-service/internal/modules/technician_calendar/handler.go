package techniciancalendar

import (
	"log/slog"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
	logger  *slog.Logger
}

func NewHandler(service Service, logger *slog.Logger) *Handler {
	if logger == nil {
		logger = slog.Default()
	}
	return &Handler{service: service, logger: logger}
}

func (h *Handler) GetCalendarAuto(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	period := c.Params("period")

	switch {
	case isValidMonthFormat(period):
		return h.getMonthlyCalendar(c, techID, period)
	case isValidDateFormat(period):
		return h.getDayCalendar(c, techID, period)
	default:
		return appErrors.BadRequest(c, "invalid period format, use YYYY-MM or YYYY-MM-DD")
	}
}

func (h *Handler) getMonthlyCalendar(c fiber.Ctx, techID uint, month string) error {
	query := CalendarQuery{
		TechnicianID: techID,
		Month:        month,
	}

	if err := query.Validate(); err != nil {
		h.logger.Warn("calendar query validation failed",
			slog.Uint64("technician_id", uint64(techID)),
			slog.String("month", month),
			slog.String("error", err.Error()),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	result, err := h.service.GetMonthlyCalendar(c.Context(), query)
	if err != nil {
		return h.handleServiceError(c, err, "failed to get calendar")
	}

	h.logger.Info("monthly calendar retrieved",
		slog.Uint64("technician_id", uint64(techID)),
		slog.String("month", month),
		slog.Int("days_count", len(result.Days)),
	)

	return c.JSON(fiber.Map{"success": true, "data": result})
}

func (h *Handler) getDayCalendar(c fiber.Ctx, techID uint, dateStr string) error {
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	date, err := booking.ParseDate(dateStr)
	if err != nil {
		return appErrors.BadRequest(c, "invalid date value")
	}

	query := CalendarDayQuery{
		TechnicianID: techID,
		Date:         dateStr,
	}

	if ts := c.Query("timeslot"); ts != "" {
		val, err := utils.ParseUint(ts)
		if err != nil {
			return appErrors.BadRequest(c, "invalid timeslot")
		}
		query.TimeSlotID = &val
	}

	result, err := h.service.GetCalendarDayBookings(c.Context(), query, date)
	if err != nil {
		return h.handleServiceError(c, err, "failed to get booking details")
	}

	h.logger.Info("calendar day bookings retrieved",
		slog.Uint64("technician_id", uint64(techID)),
		slog.String("date", dateStr),
		slog.Int("booking_count", len(result)),
	)

	return c.JSON(fiber.Map{"success": true, "data": result})
}

func (h *Handler) UpdateCalendarDate(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var req UpdateCalendarDateRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if err := req.Validate(); err != nil {
		h.logger.Warn("calendar date request validation failed",
			slog.Uint64("technician_id", uint64(techID)),
			slog.String("date", req.Date),
			slog.String("error", err.Error()),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	result, err := h.service.UpdateCalendarDate(ctx, techID, req)
	if err != nil {
		return h.handleServiceError(c, err, "failed to update calendar date")
	}

	h.logger.Info("calendar date updated",
		slog.Uint64("technician_id", uint64(techID)),
		slog.String("date", req.Date),
		slog.Bool("is_open", req.IsOpen),
	)

	return c.JSON(fiber.Map{"success": true, "message": "calendar updated successfully", "data": result})
}

func (h *Handler) UpdateTimeSlots(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	dateStr := c.Params("date")
	if !isValidDateFormat(dateStr) {
		return appErrors.BadRequest(c, "date must be in YYYY-MM-DD format")
	}

	var req UpdateTimeSlotsRequest
	req.Date = dateStr

	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if err := req.Validate(); err != nil {
		return appErrors.BadRequest(c, err.Error())
	}

	date, err := req.ParseDate()
	if err != nil {
		return appErrors.BadRequest(c, "invalid date format")
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	result, err := h.service.UpdateTimeSlotsForDate(ctx, techID, date, req)
	if err != nil {
		return h.handleServiceError(c, err, "failed to update time slots")
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "time slots updated successfully",
		"data":    result,
	})
}

func (h *Handler) UpdateDefaultTimeSlots(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var req UpdateTimeSlotsRequest
	req.IsDefault = true

	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if err := req.Validate(); err != nil {
		h.logger.Warn("default time slots request validation failed",
			slog.Uint64("technician_id", uint64(techID)),
			slog.String("error", err.Error()),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	result, err := h.service.UpdateTimeSlotsForDate(ctx, techID, time.Now(), req)
	if err != nil {
		return h.handleServiceError(c, err, "failed to update default time slots")
	}

	h.logger.Info("default time slots updated",
		slog.Uint64("technician_id", uint64(techID)),
		slog.Int("slot_count", len(result.TimeSlots)),
	)

	return c.JSON(fiber.Map{"success": true, "message": "default time slots updated successfully", "data": result})
}

func (h *Handler) handleServiceError(c fiber.Ctx, err error, defaultMsg string) error {
	h.logger.Error("service error",
		slog.String("error", err.Error()),
		slog.String("default_message", defaultMsg),
		slog.String("path", c.Path()),
		slog.String("method", c.Method()),
	)
	switch err {
	case ErrPastDate:
		return appErrors.BadRequest(c, "cannot update calendar for past dates")
	case ErrTimeSlotNotFound:
		return appErrors.BadRequest(c, err.Error())
	case ErrTechnicianNotFound:
		return appErrors.NotFound(c, "technician not found")
	case ErrInvalidDateRange, ErrInvalidMonth:
		return appErrors.BadRequest(c, err.Error())
	default:
		return appErrors.InternalError(c, defaultMsg, err)
	}
}
