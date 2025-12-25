package technicianmatching

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {

	router.Get("/", h.ListTechnicians)
	router.Get("/:id", h.GetTechnicianDetail)
	router.Post("/auto-select", h.AutoSelectTechnician)
}
