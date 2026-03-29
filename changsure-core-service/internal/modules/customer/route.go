package customer

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {

	api.Get("/", h.ListCustomers)
	api.Get("/:customerID", h.GetCustomer)
	api.Patch("/:customerID", h.UpdateCustomer)
	api.Delete("/:customerID", h.DeleteCustomer)
}
