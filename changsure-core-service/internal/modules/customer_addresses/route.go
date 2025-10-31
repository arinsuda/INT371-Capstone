package customeraddresses

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	customerAdd := router.Group("/customers/:id")

	customerAdd.Post("/", h.CreateAddress)
	customerAdd.Get("/", h.ListAddresses)
	customerAdd.Get("/:addrId", h.GetAddress)
	customerAdd.Patch("/:addrId", h.UpdateAddress)
	customerAdd.Delete("/:addrId", h.DeleteAddress)

	router.Post("/addresses/nearby", h.SearchNearby)
}