package customeraddresses

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	addr := router.Group("/customers/:id/addresses")

	addr.Post("", h.CreateAddress)           
	addr.Get("", h.ListAddresses)            
	addr.Get("/:addrId", h.GetAddress)       
	addr.Patch("/:addrId", h.UpdateAddress)  
	addr.Delete("/:addrId", h.DeleteAddress)

	router.Post("/addresses/nearby", h.SearchNearby)
}
