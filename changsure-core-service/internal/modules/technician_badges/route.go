package technician_badges

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	g := api.Group("/technician-badges")
	g.Post("/technicians/:technician_id/badges", h.Assign)
	g.Get("/technicians/:technician_id/badges", h.ListByTechnician)
	g.Delete("/:id", h.Remove)
}
