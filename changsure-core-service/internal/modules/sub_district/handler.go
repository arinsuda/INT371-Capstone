package subdistrict

import (
	customErr "changsure-core-service/internal/errors"
	"github.com/gofiber/fiber/v3"
	"strconv"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) GetSubDistrict(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return customErr.BadRequest(c, "Invalid sub-district ID")
	}

	item, err := h.service.GetByID(c.Context(), uint(id))
	if err != nil {
		return customErr.InternalError(c, "Failed to fetch sub-district", err)
	}
	if item == nil {
		return customErr.NotFound(c, "Sub-district not found")
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(item),
	})
}

func (h *Handler) ListSubDistrictByDistrict(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("district_id"), 10, 32)
	if err != nil {
		return customErr.BadRequest(c, "Invalid district ID")
	}

	list, err := h.service.ListByDistrict(c.Context(), uint(id))
	if err != nil {
		return customErr.InternalError(c, "Failed to fetch sub-districts", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponseList(list),
	})
}

func (h *Handler) ListSubDistricts(c fiber.Ctx) error {
	var (
		districtID *uint
		provinceID *uint
		q          = c.Query("q")
		limitStr   = c.Query("limit")
	)

	if v := c.Query("district_id"); v != "" {
		id64, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			return customErr.BadRequest(c, "Invalid district_id")
		}
		tmp := uint(id64)
		districtID = &tmp
	}
	if v := c.Query("province_id"); v != "" {
		id64, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			return customErr.BadRequest(c, "Invalid province_id")
		}
		tmp := uint(id64)
		provinceID = &tmp
	}

	limit := 200
	if limitStr != "" {
		n, err := strconv.Atoi(limitStr)
		if err != nil {
			return customErr.BadRequest(c, "Invalid limit")
		}
		limit = n
	}

	list, err := h.service.ListFiltered(c.Context(), districtID, provinceID, q, limit)
	if err != nil {
		return customErr.InternalError(c, "Failed to fetch sub-districts", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponseList(list),
	})
}
