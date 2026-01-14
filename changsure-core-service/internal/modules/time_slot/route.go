package timeslot

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	group := router.Group("/time-slots")
	group.Get("/", h.GetTimeSlots)
	group.Get("/technician/:technician_id", h.GetTimeSlotsByTechnicianID)
}

func (h *Handler) RegisterTechnicianRoutes(router fiber.Router) {
	group := router.Group("/time-slots")
	group.Get("/", h.GetMyTimeSlots)
	group.Put("/", h.UpdateMyTimeSlots)
	group.Delete("/", h.ResetMyTimeSlots)
}
