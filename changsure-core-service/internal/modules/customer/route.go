package customers

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	// Profile routes
	router.Get("/profile", h.GetProfile)
	router.Patch("/profile", h.UpdateProfile)

	// Admin/General routes
	router.Get("/", h.ListCustomers)
	router.Get("/:id", h.GetCustomer)

	router.Patch("/:id", h.UpdateCustomer)
	router.Delete("/:id", h.DeleteCustomer)
}
