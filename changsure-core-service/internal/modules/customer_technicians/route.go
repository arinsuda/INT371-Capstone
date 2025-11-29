package customer_technicians

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(r fiber.Router) {
	g := r.Group("/technicians")

	g.Get("/", h.List)
	g.Get("/:id", h.GetByID)
	g.Post("/auto-select", h.AutoSelect)
}
