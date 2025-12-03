package customeraddress

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

	me.Post("", h.CreateCustomerAddress)
	me.Get("", h.ListCustomerAddresses)
	me.Get("/:id", h.GetCustomerAddress)
	me.Patch("/:id", h.UpdateCustomerAddress)
	me.Delete("/:id", h.DeleteCustomerAddress)

	me.Patch("/:id/primary", h.SetPrimaryCustomerAddress)

	r.Post("/technicians/nearby", h.SearchNearbyTechnicians)
}
