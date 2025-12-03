package province

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	g := router.Group("/provinces")

	g.Post("/", h.CreateProvince)
	g.Get("/", h.ListProvinces)
	g.Get("/:id", h.GetProvince)
	g.Patch("/:id", h.UpdateProvince)
	g.Delete("/:id", h.DeleteProvince)
}