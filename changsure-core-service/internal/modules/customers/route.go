package customers

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	g := router.Group("")

	g.Get("/profile", h.GetProfile)
	g.Patch("/profile", h.UpdateProfile)

	g.Get("/", h.ListCustomers)
	g.Get("/:id", h.GetCustomer)
	g.Patch("/:id", h.UpdateCustomer)
	g.Delete("/:id", h.DeleteCustomer)
}
