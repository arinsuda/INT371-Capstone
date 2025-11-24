package technician_services

import (
	"net/http"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc Service }

func NewHandler(s Service) *Handler { return &Handler{svc: s} }

func (h *Handler) PostPricing(c fiber.Ctx) error {
	var req TechnicianPricingReq
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	id, err := h.svc.SetPricing(c.Context(), req)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}
	return c.Status(http.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    fiber.Map{"pricing_id": id},
	})
}

func (h *Handler) SearchTechnicians(c fiber.Ctx) error {
	var q SearchTechniciansQuery
	if err := c.Bind().Query(&q); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	items, total, err := h.svc.SearchTechnicians(c.Context(), q)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items":     items,
			"total":     total,
			"page":      q.Page,
			"page_size": q.PageSize,
		},
	})
}
