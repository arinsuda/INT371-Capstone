package customers

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	customers := router.Group("/customers")

	customers.Post("/", h.CreateCustomer)
	customers.Get("/", h.ListCustomers)
	customers.Get("/:id", h.GetCustomer)
	customers.Patch("/:id", h.UpdateCustomer)
	customers.Delete("/:id", h.DeleteCustomer)
}