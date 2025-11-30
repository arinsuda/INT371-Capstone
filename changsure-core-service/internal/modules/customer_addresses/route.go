package customer_addresses

import (
	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router, cfg *config.Config) {

	me := r.Group("/me/addresses",
		middleware.AuthMiddleware(cfg),
		middleware.CustomerOnly(),
	)

	me.Post("", h.CreateAddress)
	me.Get("", h.ListAddresses)
	me.Get("/:id", h.GetAddress)
	me.Patch("/:id", h.UpdateAddress)
	me.Delete("/:id", h.DeleteAddress)

	me.Patch("/:id/primary", h.SetPrimaryAddress)

	r.Post("/technicians/nearby", h.SearchNearby)
}
