package technicianmatching

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	api.Get("/", h.ListTechnicians)
	api.Post("/auto-select", h.AutoSelectTechnician)
}
