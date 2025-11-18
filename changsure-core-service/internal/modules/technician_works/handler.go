package technician_works

import (
	"context"
	"time"

	utils "changsure-core-service/pkg/utils"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc Service
}

func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) Create(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil || techID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}

	var body CreateTechnicianWorkDTO
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}
	if body.Title == "" {
		return fiber.NewError(fiber.StatusBadRequest, "title is required")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	res, err := h.svc.Create(ctx, techID, body)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    res,
	})
}

func (h *Handler) Get(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil || techID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}
	workID, err := utils.ParseUintParam(c, "id")
	if err != nil || workID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid work id")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	res, err := h.svc.Get(ctx, techID, workID)
	if err != nil {
		return fiber.NewError(fiber.StatusNotFound, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    res,
	})
}

func (h *Handler) List(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil || techID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}

	var q ListTechnicianWorksQuery
	if err := c.Bind().Query(&q); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid query")
	}
	if q.Page <= 0 {
		q.Page = 1
	}
	if q.PerPage <= 0 || q.PerPage > 100 {
		q.PerPage = 10
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	items, total, err := h.svc.List(ctx, techID, q)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items":    items,
			"page":     q.Page,
			"per_page": q.PerPage,
			"total":    total,
		},
	})
}

func (h *Handler) Update(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil || techID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}
	workID, err := utils.ParseUintParam(c, "id")
	if err != nil || workID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid work id")
	}

	var body UpdateTechnicianWorkDTO
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	res, err := h.svc.Update(ctx, techID, workID, body)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    res,
	})
}

func (h *Handler) Delete(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil || techID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}
	workID, err := utils.ParseUintParam(c, "id")
	if err != nil || workID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid work id")
	}

	hard := c.Query("hard") == "true"

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	if err := h.svc.Delete(ctx, techID, workID, hard); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	// ✅ ตามที่คุณขอ: ใช้ 200 + message แทน 204
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "work deleted successfully",
	})
}
