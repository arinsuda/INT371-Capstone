package district

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

func (h *Handler) ListDistrictByProvince(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("province_id"), 10, 32)
	if err != nil {
		return customErr.BadRequest(c, "Invalid province ID")
	}

	list, err := h.service.ListByProvince(c.Context(), uint(id))
	if err != nil {
		return customErr.InternalError(c, "Failed to fetch districts", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponseList(list),
	})
}

func (h *Handler) ListDistricts(c fiber.Ctx) error {
	var (
		provinceID    *uint
		subDistrictID *uint
		q             = c.Query("q")
		limitStr      = c.Query("limit")
	)

	if v := c.Query("province_id"); v != "" {
		id64, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			return customErr.BadRequest(c, "Invalid province_id")
		}
		tmp := uint(id64)
		provinceID = &tmp
	}
	if v := c.Query("sub_district_id"); v != "" {
		id64, err := strconv.ParseUint(v, 10, 32)
		if err != nil {
			return customErr.BadRequest(c, "Invalid sub_district_id")
		}
		tmp := uint(id64)
		subDistrictID = &tmp
	}

	limit := 200
	if limitStr != "" {
		n, err := strconv.Atoi(limitStr)
		if err != nil {
			return customErr.BadRequest(c, "Invalid limit")
		}
		limit = n
	}

	list, err := h.service.ListFiltered(c.Context(), provinceID, subDistrictID, q, limit)
	if err != nil {
		return customErr.InternalError(c, "Failed to fetch districts", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponseList(list),
	})
}
