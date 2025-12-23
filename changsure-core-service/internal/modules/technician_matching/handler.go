package technicianmatching

import (
	"strconv"

	"changsure-core-service/pkg/utils"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc Service
}

func NewHandler(s Service) *Handler {
	return &Handler{svc: s}
}

func (h *Handler) ListTechnicians(c fiber.Ctx) error {
	customerID := utils.GetUserID(c)
	if customerID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	var q TechnicianSearchQuery
	if err := c.Bind().Query(&q); err != nil {
		return fiber.NewError(400, "invalid query")
	}

	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 {
		q.PageSize = 20
	}

	data, total, err := h.svc.ListTechnicians(c.Context(), customerID, q)
	if err != nil {
		return fiber.NewError(500, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items":     data,
			"total":     total,
			"page":      q.Page,
			"page_size": q.PageSize,
		},
	})
}

func (h *Handler) GetTechnicianDetail(c fiber.Ctx) error {
	id, _ := strconv.Atoi(c.Params("id"))

	res, err := h.svc.GetTechnicianDetail(c.Context(), uint(id))
	if err != nil {
		return fiber.NewError(404, "technician not found")
	}
	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) AutoSelectTechnician(c fiber.Ctx) error {
	customerID := utils.GetUserID(c)
	if customerID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	var req AutoSelectRequest
	if err := c.Bind().Body(&req); err != nil {
		return fiber.NewError(400, "invalid body")
	}

	res, err := h.svc.AutoSelectTechnician(c.Context(), customerID, req)
	if err != nil {
		return fiber.NewError(500, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}
