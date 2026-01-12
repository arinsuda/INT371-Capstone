package customeraddress

import (
	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router, cfg *config.Config) {
	g := r.Group("/addresses",
		middleware.AuthMiddleware(cfg),
		middleware.CustomerOnly(),
	)

	g.Post("", h.Create)
	g.Get("", h.List)
	g.Get("/:id", h.Get)
	g.Put("/:id", h.Update)
	g.Delete("/:id", h.Delete)
	g.Patch("/:id/primary", h.SetPrimary)
}
