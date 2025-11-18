package technician_works

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	g := api.Group("/technicians")

	g.Post("/:technician_id/works", h.Create)
	g.Get("/:technician_id/works", h.List)
	g.Get("/:technician_id/works/:id", h.Get)
	g.Patch("/:technician_id/works/:id", h.Update)
	g.Delete("/:technician_id/works/:id", h.Delete)
}
