package technicians

import (
	"context"
	"net/http"
	"strconv"
	"time"

	utils "changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc Service }

func NewHandler(s Service) *Handler { return &Handler{svc: s} }

func techIDFromLocals(c fiber.Ctx) uint {
	switch v := c.Locals("tech_id").(type) {
	case uint:
		return v
	case uint64:
		return uint(v)
	case int:
		if v > 0 {
			return uint(v)
		}
	case string:
		if id, err := strconv.ParseUint(v, 10, 64); err == nil {
			return uint(id)
		}
	}
	return 0
}

func (h *Handler) PostProfile(c fiber.Ctx) error {
	var req TechnicianProfileReq
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false, "error": err.Error(),
		})
	}

	techID := techIDFromLocals(c)

	id, err := h.svc.UpsertProfile(c.Context(), techID, req)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false, "error": err.Error(),
		})
	}
	return c.Status(http.StatusCreated).JSON(fiber.Map{
		"success": true, "data": fiber.Map{"technician_id": id},
	})
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
	techID := techIDFromLocals(c)
	if techID == 0 {
		if idStr := c.Query("id"); idStr != "" {
			if id, err := strconv.ParseUint(idStr, 10, 64); err == nil {
				techID = uint(id)
			}
		}
	}
	if techID == 0 {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "technician id is required",
		})
	}

	res, err := h.svc.GetProfile(c.Context(), techID)
	if err != nil {
		return c.Status(http.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    res,
	})
}

func (h *Handler) PatchProvinces(c fiber.Ctx) error {
	var req TechnicianProvincesPatchReq
	if err := c.Bind().Body(&req); err != nil || len(req.ProvinceIDs) == 0 {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false, "error": "invalid body: province_ids required",
		})
	}

	techID := techIDFromLocals(c)
	if techID == 0 {
		if idStr := c.Query("id"); idStr != "" {
			if id, err := strconv.ParseUint(idStr, 10, 64); err == nil {
				techID = uint(id)
			}
		}
	}
	if techID == 0 {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false, "error": "technician id is required",
		})
	}

	if err := h.svc.UpdateProvinces(c.Context(), techID, req.ProvinceIDs); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false, "error": err.Error(),
		})
	}
	return c.JSON(fiber.Map{"success": true})
}

func (h *Handler) AddService(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "id")
	if err != nil || techID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}

	var body AddTechServiceReq
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}

	if body.ProvinceID == 0 || body.ServiceID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "province_id and service_id are required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	result, err := h.svc.AddService(ctx, techID, body)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "service added to technician",
		"data":    result,
	})
}

func (h *Handler) RemoveService(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "id")
	if err != nil || techID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}

	var body RemoveTechServiceReq
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}
	if body.ProvinceID == 0 || body.ServiceID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "province_id and service_id are required")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := h.svc.RemoveService(ctx, techID, body); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "service removed successfully",
	})
}
