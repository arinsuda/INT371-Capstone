package technicianaddress

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	api.Post("/nearby", h.SearchNearby)

	tech_address := api.Group("/:technicianID/addresses")

	tech_address.Post("/", h.Create)
	tech_address.Get("/", h.List)
	tech_address.Get("/:addressID", h.Get)
	tech_address.Put("/:addressID", h.Update)
	tech_address.Delete("/:addressID", h.Delete)
	tech_address.Patch("/:addressID", h.SetPrimary)
}
