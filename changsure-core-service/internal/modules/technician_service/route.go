package technicianservice

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Post("/technician/pricing", h.PostPricing)
	router.Get("/technicians", h.SearchTechnicians)
}
