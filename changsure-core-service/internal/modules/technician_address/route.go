package technicianaddress

import (
	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router, cfg *config.Config) {

	me := r.Group("/addresses",
		middleware.AuthMiddleware(cfg),
		middleware.TechnicianOnly(),
	)

	me.Post("", h.Create)
	me.Get("", h.List)
	me.Get("/:id", h.Get)
	me.Put("/:id", h.Update)
	me.Delete("/:id", h.Delete)

	me.Patch("/:id/primary", h.SetPrimary)
}

func (h *Handler) RegisterRoutesPublic(r fiber.Router, cfg *config.Config) {
	r.Get("/technicians/:id/addresses", h.ListPublicAddresses)
	r.Post("/technicians/nearby", h.SearchNearby)
}
