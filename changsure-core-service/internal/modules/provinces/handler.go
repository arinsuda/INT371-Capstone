package provinces

import (
	"errors"
	"strconv"

	"changsure-core-service/internal/middleware"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) CreateProvince(c fiber.Ctx) error {
	var req CreateProvinceRequest
	if err := c.Bind().JSON(&req); err != nil {
		return badRequest(c, "Invalid request body")
	}
	if err := req.Validate(); err != nil {
		return badRequest(c, err.Error())
	}

	ctx := middleware.GetContext(c)
	p, err := h.service.CreateProvince(ctx, &req)
	if err != nil {
		return internalErr(c, "Failed to create province", err)
	}

	total, _ := h.service.CountProvinces(ctx)
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status": "success",
		"total":  total,
		"data": fiber.Map{
			"id":      p.ID,
			"name_th": p.NameTH,
		},
	})
}

func (h *Handler) GetProvince(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return badRequest(c, "Invalid province ID")
	}

	ctx := middleware.GetContext(c)
	p, err := h.service.GetProvince(ctx, uint(id))
	if err != nil {
		if errors.Is(err, ErrProvinceNotFound) {
			return notFound(c, "Province not found")
		}
		return internalErr(c, "Failed to get province", err)
	}

	total, _ := h.service.CountProvinces(ctx)
	return c.JSON(fiber.Map{
		"status": "success",
		"total":  total,
		"data": fiber.Map{
			"id":      p.ID,
			"name_th": p.NameTH,
		},
	})
}

func (h *Handler) UpdateProvince(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return badRequest(c, "Invalid province ID")
	}

	var req UpdateProvinceRequest
	if err := c.Bind().JSON(&req); err != nil {
		return badRequest(c, "Invalid request body")
	}
	if err := req.Validate(); err != nil {
		return badRequest(c, err.Error())
	}

	ctx := middleware.GetContext(c)
	p, err := h.service.UpdateProvince(ctx, uint(id), &req)
	if err != nil {
		if errors.Is(err, ErrProvinceNotFound) {
			return notFound(c, "Province not found")
		}
		return internalErr(c, "Failed to update province", err)
	}

	total, _ := h.service.CountProvinces(ctx)
	return c.JSON(fiber.Map{
		"status": "success",
		"total":  total,
		"data": fiber.Map{
			"id":      p.ID,
			"name_th": p.NameTH,
		},
	})
}

func (h *Handler) DeleteProvince(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return badRequest(c, "Invalid province ID")
	}

	ctx := middleware.GetContext(c)
	if err := h.service.DeleteProvince(ctx, uint(id)); err != nil {
		if errors.Is(err, ErrProvinceNotFound) {
			return notFound(c, "Province not found")
		}
		return internalErr(c, "Failed to delete province", err)
	}

	total, _ := h.service.CountProvinces(ctx)
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Province deleted successfully",
		"total":   total,
	})
}

func (h *Handler) ListProvinces(c fiber.Ctx) error {
	ctx := middleware.GetContext(c)

	items, err := h.service.ListProvinces(ctx)
	if err != nil {
		return internalErr(c, "Failed to list provinces", err)
	}

	total, _ := h.service.CountProvinces(ctx)
	out := make([]fiber.Map, 0, len(items))
	for _, p := range items {
		out = append(out, fiber.Map{"id": p.ID, "name_th": p.NameTH})
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"total":  total,
		"data":   out,
	})
}

func badRequest(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"status": "error", "message": msg})
}
func notFound(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"status": "error", "message": msg})
}
func internalErr(c fiber.Ctx, msg string, _ error) error {
	return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"status": "error", "message": msg})
}
