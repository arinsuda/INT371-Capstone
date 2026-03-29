package subdistrict

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	api.Get("/sub-districts", h.ListSubDistricts)
	api.Get("/sub-districts/:sub_district_id", h.GetSubDistrict)
	api.Get("/districts/:district_id/sub-districts", h.ListSubDistrictByDistrict)
}
