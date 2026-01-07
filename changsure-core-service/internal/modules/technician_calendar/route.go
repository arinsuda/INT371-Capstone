package techniciancalendar

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/calendar", h.GetTechnicianCalendar)
}
