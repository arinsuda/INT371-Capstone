package technician_services

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	technicians := router.Group("")

	technicians.Post("/technician/pricing", h.PostPricing)
	technicians.Get("/technicians", h.SearchTechnicians)
}
