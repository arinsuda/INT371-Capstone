package technician_addresses

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {
	r.Post("/technicians/addresses", h.AddAddress)
	r.Get("/technicians/addresses", h.ListAddresses)
	r.Patch("/technicians/addresses/:id", h.UpdateAddress)
	r.Delete("/technicians/addresses/:id", h.DeleteAddress)
}
