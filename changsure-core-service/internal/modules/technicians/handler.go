package technicians

import (
	"net/http"
	"strconv"

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
