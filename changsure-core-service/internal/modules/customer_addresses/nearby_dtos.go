package customeraddresses

import (
	"github.com/gofiber/fiber/v3"
	"changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/validation"
)

type SearchNearbyAddressRequest struct {
	Latitude  float64 `json:"latitude" validate:"required,lat"`
	Longitude float64 `json:"longitude" validate:"required,lon"`
	RadiusKm  float64 `json:"radius_km" validate:"required,min=0"`
}

func (h *Handler) SearchNearby(c fiber.Ctx) error {
	var req SearchNearbyAddressRequest
	if err := c.Bind().JSON(&req); err != nil {
		return errors.BadRequest(c, "Invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return errors.ValidationError(c, details)
	}

	ctx := middleware.GetContext(c)
	list, err := h.service.FindNearby(ctx, req.Latitude, req.Longitude, req.RadiusKm, 50)
	if err != nil {
		return errors.InternalError(c, "Failed to search nearby addresses", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data": fiber.Map{
			"addresses": ToResponseList(list),
			"count":     len(list),
		},
	})
}
