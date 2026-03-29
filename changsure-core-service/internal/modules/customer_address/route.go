package customeraddress

import (
	"changsure-core-service/internal/config"
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(api fiber.Router, cfg *config.Config) {
	g := api.Group("/:customerID/addresses")

	g.Post("/", h.Create)
	g.Get("/", h.List)
	g.Get("/:addressID", h.Get)
	g.Put("/:addressID", h.Update)
	g.Delete("/:addressID", h.Delete)
	g.Patch("/:addressID", h.SetPrimary)
}
