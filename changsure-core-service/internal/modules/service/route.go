package service

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {
	g := r.Group("/services")
	g.Post("/", h.Create)
	g.Get("/", h.List)
	g.Get("/all", h.ListAllNoPagination)
	g.Get("/menu", h.GetMenu)
	g.Get("/menu/:id", h.GetMenuDetail)
	g.Get("/:id", h.GetByID)
	g.Patch("/:id", h.Update)
	g.Delete("/:id", h.Delete)
}
