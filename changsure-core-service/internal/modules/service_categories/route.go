package service_categories

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {
	g := r.Group("/service-categories")
	g.Get("/", h.List)
	g.Get("/:id", h.GetByID)
	g.Post("/:id/icon", h.UploadIcon)
}
