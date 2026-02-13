package techniciancalendar

import (
	"github.com/gofiber/fiber/v3"
)

// RegisterRoutes - Public routes (for customers/anyone to view technician calendar)
func (h *Handler) RegisterRoutes(router fiber.Router) {
	// GET /api/calendar?technician_id=123&month=2026-02
	router.Get("/calendar", h.GetTechnicianCalendar)
}

// RegisterTechnicianRoutes - Protected routes for technicians
func (h *Handler) RegisterTechnicianRoutes(router fiber.Router) {
	// GET /api/technician/calendar?month=2026-02
	router.Get("/calendar", h.GetMyCalendar)

	// PATCH /api/technician/calendar
	// Body: { "date": "2026-02-15", "is_open": false }
	router.Patch("/calendar/date", h.UpdateMyCalendarDate)

	// PATCH /api/technicians/me/calendar?month=2026-02-15
	// Body: { "time_slot_ids": [1, 2], "is_default": false }
	router.Patch("/calendar/slots", h.UpdateMyTimeSlots)
}
