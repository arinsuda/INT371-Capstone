package technicianbadge

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	r := api.Group("/:technician_id/badges")

	r.Post("/", h.Assign)
	r.Get("/", h.ListByTechnician)
	r.Delete("/:badge_id", h.Unassign)
}
