package customers

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {

	r.Get("/profile", h.GetProfile)
	r.Patch("/profile", h.UpdateProfile)

	r.Get("/", h.ListCustomers)

	r.Get("/:id", h.GetCustomer)
	r.Patch("/:id", h.UpdateCustomer)
	r.Delete("/:id", h.DeleteCustomer)
}
