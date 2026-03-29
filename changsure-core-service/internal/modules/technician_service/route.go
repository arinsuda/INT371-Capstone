package technicianservice

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {

	router.Post("/pricing", h.UpsertPricing)

	router.Get("/search", h.SearchTechnicians)
}
