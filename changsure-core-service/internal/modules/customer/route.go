package customers

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {

	customer := r.Group("/me")

	customer.Get("/profile", h.GetProfile)
	customer.Patch("/profile", h.UpdateProfile)

	customer.Get("/", h.ListCustomers)

	customer.Get("/:id", h.GetCustomer)
	customer.Patch("/:id", h.UpdateCustomer)
	customer.Delete("/:id", h.DeleteCustomer)
}
