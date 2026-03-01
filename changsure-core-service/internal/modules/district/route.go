package district

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	api.Get("/districts", h.ListDistricts)
	api.Get("/provinces/:province_id/districts", h.ListDistrictByProvince)
}
