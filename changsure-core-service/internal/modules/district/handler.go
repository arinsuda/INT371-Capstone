package district

import (
	appErrors "changsure-core-service/internal/errors"
	"strconv"

	"changsure-core-service/pkg/utils"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) ListDistrictByProvince(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "province_id")
	if err != nil {
		return appErrors.BadRequest(c, "Invalid province ID")
	}

	list, err := h.service.ListByProvince(c.Context(), id)
	if err != nil {
		return appErrors.InternalError(c, "Failed to fetch districts", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    ToResponseList(list),
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
		id, err := utils.ParseUintParam(c, "province_id")
		if err != nil {
			return appErrors.BadRequest(c, "Invalid province_id")
		}
		provinceID = &id
	}

	if v := c.Query("sub_district_id"); v != "" {
		id, err := utils.ParseUintParam(c, "sub_district_id")
		if err != nil {
			return appErrors.BadRequest(c, "Invalid sub_district_id")
		}
		subDistrictID = &id
	}

	limit := 200
	if limitStr != "" {
		n, err := strconv.Atoi(limitStr)
		if err != nil {
			return appErrors.BadRequest(c, "Invalid limit")
		}
		if n >= 1 && n <= 200 {
			limit = n
		}
	}

	list, err := h.service.ListFiltered(c.Context(), provinceID, subDistrictID, q, limit)
	if err != nil {
		return appErrors.InternalError(c, "Failed to fetch districts", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    ToResponseList(list),
	})
}
