package technician_works

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	g := api.Group("")

	g.Post("/works", h.Create)
	g.Get("/works", h.List)
	g.Get("/works/:id", h.Get)
	g.Patch("/works/:id", h.Update)
	g.Delete("/works/:id", h.Delete)
}
