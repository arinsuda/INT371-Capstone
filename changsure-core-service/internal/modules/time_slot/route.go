package timeslot

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/time-slots", h.GetTimeSlots)
}
