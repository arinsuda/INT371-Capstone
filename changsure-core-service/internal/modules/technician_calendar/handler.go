package techniciancalendar

import (
	"log/slog"
	"strconv"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/validation"
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
	return &Handler{
		service: service,
		logger:  logger,
	}
}

func (h *Handler) GetTechnicianCalendar(c fiber.Ctx) error {
	var query CalendarQuery

	if err := c.Bind().Query(&query); err != nil {
		h.logger.Warn("failed to bind query parameters",
			slog.String("error", err.Error()),
			slog.String("path", c.Path()),
		)
		return appErrors.BadRequest(c, "invalid query parameters")
	}

	if err := query.Validate(); err != nil {
		h.logger.Warn("query validation failed",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(query.TechnicianID)),
			slog.String("month", query.Month),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	result, err := h.service.GetMonthlyCalendar(c.Context(), query)
	if err != nil {
		return h.handleServiceError(c, err, "failed to get calendar")
	}

	h.logger.Info("calendar retrieved",
		slog.Uint64("technician_id", uint64(query.TechnicianID)),
		slog.String("month", query.Month),
		slog.Int("days_count", len(result.Days)),
	)

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}

func (h *Handler) GetMyCalendar(c fiber.Ctx) error {
	technicianID, err := h.getTechnicianID(c)
	if err != nil {
		return err
	}

	var query CalendarQuery
	query.TechnicianID = technicianID

	query.Month = c.Query("month")

	if query.Month == "" {
		return appErrors.BadRequest(c, "month parameter is required")
	}

	if err := query.Validate(); err != nil {
		h.logger.Warn("query validation failed",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(technicianID)),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	result, err := h.service.GetMonthlyCalendar(c.Context(), query)
	if err != nil {
		return h.handleServiceError(c, err, "failed to get calendar")
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}

func (h *Handler) GetMyCalendarByDate(c fiber.Ctx) error {
	technicianID, err := h.getTechnicianID(c)
	if err != nil {
		return err
	}

	var query CalendarDayQuery
	query.TechnicianID = technicianID
	query.Date = c.Query("date")

	if ts := c.Query("timeslot"); ts != "" {
		val, err := strconv.ParseUint(ts, 10, 64)
		if err != nil {
			return appErrors.BadRequest(c, "invalid timeslot")
		}
		tmp := uint(val)
		query.TimeSlotID = &tmp
	}

	if query.Date == "" {
		h.logger.Warn("date parameter is required",
			slog.Uint64("technician_id", uint64(technicianID)),
		)
		return appErrors.BadRequest(c, "date parameter is required")
	}

	if !isValidDateFormat(query.Date) {
		h.logger.Warn("invalid date format",
			slog.String("date", query.Date),
		)
		return appErrors.BadRequest(c, "date must be in YYYY-MM-DD format")
	}

	date, err := booking.ParseDate(query.Date)
	if err != nil {
		h.logger.Warn("failed to parse date",
			slog.String("error", err.Error()),
			slog.String("date", query.Date),
		)
		return appErrors.BadRequest(c, "invalid date value")
	}

	result, err := h.service.GetCalendarDayBookings(c.Context(), query, date)
	if err != nil {
		return h.handleServiceError(c, err, "failed to get booking details")
	}

	h.logger.Info("booking details retrieved",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", query.Date),
		slog.Int("booking_count", len(result)),
	)

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}

func (h *Handler) UpdateMyCalendarDate(c fiber.Ctx) error {
	technicianID, err := h.getTechnicianID(c)
	if err != nil {
		return err
	}

	var req UpdateCalendarDateRequest
	if err := c.Bind().Body(&req); err != nil {
		h.logger.Warn("failed to parse request body",
			slog.String("error", err.Error()),
		)
		return appErrors.BadRequest(c, "invalid request body")
	}

	if err := req.Validate(); err != nil {
		h.logger.Warn("request validation failed",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(technicianID)),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	result, err := h.service.UpdateCalendarDate(c.Context(), technicianID, req)
	if err != nil {
		return h.handleServiceError(c, err, "failed to update calendar date")
	}

	h.logger.Info("calendar date updated",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", req.Date),
		slog.Bool("is_open", req.IsOpen),
	)

	return c.JSON(fiber.Map{
		"success": true,
		"message": "calendar updated successfully",
		"data":    result,
	})
}

func (h *Handler) UpdateMyTimeSlots(c fiber.Ctx) error {
	technicianID, err := h.getTechnicianID(c)
	if err != nil {
		return err
	}

	var req UpdateTimeSlotsRequest
	req.Date = c.Query("date")

	if err := c.Bind().Body(&req); err != nil {
		h.logger.Warn("failed to parse request body",
			slog.String("error", err.Error()),
		)
		return appErrors.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	if err := req.Validate(); err != nil {
		h.logger.Warn("request validation failed",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(technicianID)),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	date, err := req.ParseDate()
	if err != nil {
		h.logger.Warn("failed to parse date",
			slog.String("error", err.Error()),
			slog.String("date", req.Date),
		)
		return appErrors.BadRequest(c, "invalid date format")
	}

	result, err := h.service.UpdateTimeSlotsForDate(c.Context(), technicianID, date, req)
	if err != nil {
		return h.handleServiceError(c, err, "failed to update time slots")
	}

	h.logger.Info("time slots updated",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", result.Date),
		slog.Bool("is_default", req.IsDefault),
		slog.Int("slot_count", len(result.TimeSlots)),
	)

	return c.JSON(fiber.Map{
		"success": true,
		"message": "time slots updated successfully",
		"data":    result,
	})
}

func (h *Handler) getTechnicianID(c fiber.Ctx) (uint, error) {
	technicianID := utils.GetUserID(c)
	if technicianID == 0 {
		h.logger.Warn("technician_id not found in context",
			slog.String("path", c.Path()),
		)
		return 0, appErrors.Unauthorized(c, "authentication required")
	}
	return technicianID, nil
}

func (h *Handler) handleServiceError(c fiber.Ctx, err error, defaultMsg string) error {
	h.logger.Error("service error",
		slog.String("error", err.Error()),
		slog.String("default_message", defaultMsg),
		slog.String("path", c.Path()),
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
