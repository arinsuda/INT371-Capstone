package technicianservice

import (
	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc Service }

func NewHandler(s Service) *Handler { return &Handler{svc: s} }

func (h *Handler) UpsertPricing(c fiber.Ctx) error {
	techID, ok := middleware.GetUserID(c)
	if !ok {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req UpsertPricingReq
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	id, err := h.svc.UpsertPricing(c.Context(), techID, req)
	if err != nil {
		return appErrors.BadRequest(c, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    fiber.Map{"pricing_id": id},
	})
}

func (h *Handler) SearchTechnicians(c fiber.Ctx) error {
	var q SearchTechniciansQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query parameters")
	}
	if q.ServiceID == 0 {
		return appErrors.BadRequest(c, "service_id is required")
	}

	result, err := h.svc.SearchTechnicians(c.Context(), q)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	return c.JSON(fiber.Map{"success": true, "data": result})
}
