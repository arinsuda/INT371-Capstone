package techniciancalendar

import (
	"log/slog"

	appErrors "changsure-core-service/internal/errors"
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

// ===========================
// Public Endpoints
// ===========================

// GetTechnicianCalendar - Public endpoint for viewing any technician's calendar
// GET /api/calendar?technician_id=123&month=2026-02
func (h *Handler) GetTechnicianCalendar(c fiber.Ctx) error {
	var query CalendarQuery

	// Bind query parameters
	if err := c.Bind().Query(&query); err != nil {
		h.logger.Warn("failed to bind query parameters",
			slog.String("error", err.Error()),
			slog.String("path", c.Path()),
		)
		return appErrors.BadRequest(c, "invalid query parameters")
	}

	// Validate query
	if err := query.Validate(); err != nil {
		h.logger.Warn("query validation failed",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(query.TechnicianID)),
			slog.String("month", query.Month),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	// Get calendar
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

// ===========================
// Technician-only Endpoints
// ===========================

// GetMyCalendar - Technician views their own calendar
// GET /api/technician/calendar?month=2026-02
func (h *Handler) GetMyCalendar(c fiber.Ctx) error {
	technicianID, err := h.getTechnicianID(c)
	if err != nil {
		return err
	}

	// Build query
	var query CalendarQuery
	query.TechnicianID = technicianID
	query.Month = c.Query("month")

	if query.Month == "" {
		return appErrors.BadRequest(c, "month parameter is required")
	}

	// Validate
	if err := query.Validate(); err != nil {
		h.logger.Warn("query validation failed",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(technicianID)),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	// Get calendar
	result, err := h.service.GetMonthlyCalendar(c.Context(), query)
	if err != nil {
		return h.handleServiceError(c, err, "failed to get calendar")
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}

// UpdateMyCalendarDate - Update open/closed status for a specific date
// PATCH /api/technician/calendar
// Body: { "date": "2026-02-15", "is_open": false }
func (h *Handler) UpdateMyCalendarDate(c fiber.Ctx) error {
	technicianID, err := h.getTechnicianID(c)
	if err != nil {
		return err
	}

	// Parse request body
	var req UpdateCalendarDateRequest
	if err := c.Bind().Body(&req); err != nil {
		h.logger.Warn("failed to parse request body",
			slog.String("error", err.Error()),
		)
		return appErrors.BadRequest(c, "invalid request body")
	}

	// Validate
	if err := req.Validate(); err != nil {
		h.logger.Warn("request validation failed",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(technicianID)),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	// Update
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

// UpdateMyTimeSlots - Configure time slots for specific date or default
// PATCH /api/technicians/me/calendar?month=2026-02-15
// Body: { "time_slot_ids": [1, 2], "is_default": false }
func (h *Handler) UpdateMyTimeSlots(c fiber.Ctx) error {
	technicianID, err := h.getTechnicianID(c)
	if err != nil {
		return err
	}

	// Parse request
	var req UpdateTimeSlotsRequest
	req.Month = c.Query("month")

	if err := c.Bind().Body(&req); err != nil {
		h.logger.Warn("failed to parse request body",
			slog.String("error", err.Error()),
		)
		return appErrors.BadRequest(c, "invalid request body")
	}

	// Validate struct tags
	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	// Validate business logic
	if err := req.Validate(); err != nil {
		h.logger.Warn("request validation failed",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(technicianID)),
		)
		return appErrors.BadRequest(c, err.Error())
	}

	// Parse date
	date, err := req.ParseDate()
	if err != nil {
		h.logger.Warn("failed to parse date",
			slog.String("error", err.Error()),
			slog.String("month", req.Month),
		)
		return appErrors.BadRequest(c, "invalid date format")
	}

	// Update
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

// ===========================
// Helper Methods
// ===========================

// getTechnicianID extracts technician ID from context
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

// handleServiceError maps service errors to appropriate HTTP responses
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
