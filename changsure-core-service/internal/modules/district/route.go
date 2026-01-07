package district

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(r fiber.Router) {
	r.Get("/provinces/:province_id/districts", h.ListDistrictByProvince)
	r.Get("/districts", h.ListDistricts)
}
