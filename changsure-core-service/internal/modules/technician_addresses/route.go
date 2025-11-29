package technician_addresses

import (
	"github.com/gofiber/fiber/v3"

	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
)

func (h *Handler) RegisterRoutes(r fiber.Router, cfg *config.Config) {

	me := r.Group(
		"/me",
		middleware.AuthMiddleware(cfg),
		middleware.TechnicianOnly(),
	)

	me.Post("/addresses", h.AddAddress)
	me.Get("/addresses", h.ListMyAddresses)
	me.Patch("/addresses/:id", h.UpdateMyAddress)
	me.Patch("/addresses/:id/primary", h.SetPrimaryAddress)
	me.Delete("/addresses/:id", h.DeleteMyAddress)

	r.Get("/:id/addresses", h.PublicAddresses)
}
