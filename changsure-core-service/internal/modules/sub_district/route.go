package subdistrict

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(r fiber.Router) {
	r.Get("/districts/:district_id/sub-districts", h.ListSubDistrictByDistrict)
	r.Get("/sub-districts", h.ListSubDistricts)
}
