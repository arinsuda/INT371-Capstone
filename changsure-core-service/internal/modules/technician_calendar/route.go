package techniciancalendar

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {

	router.Get("/calendar", h.GetTechnicianCalendar)
}

func (h *Handler) RegisterTechnicianRoutes(router fiber.Router) {

	router.Get("/calendar", h.GetMyCalendar)
	router.Get("/calendar/day", h.GetMyCalendarByDate)
	router.Patch("/calendar/date", h.UpdateMyCalendarDate)
	router.Patch("/calendar/slots", h.UpdateMyTimeSlots)
}
