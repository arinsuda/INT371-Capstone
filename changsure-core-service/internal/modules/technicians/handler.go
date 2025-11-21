package technicians

import (
	"net/http"
	"strconv"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc Service }

func NewHandler(s Service) *Handler { return &Handler{svc: s} }

func techIDFromLocals(c fiber.Ctx) uint {
	if v := c.Locals("userID"); v != nil {
		switch x := v.(type) {
		case uint:
			return x
		case uint64:
			return uint(x)
		case int:
			if x > 0 {
				return uint(x)
			}
		case string:
			if id, err := strconv.ParseUint(x, 10, 64); err == nil {
				return uint(id)
			}
		}
	}
	if v := c.Locals("tech_id"); v != nil {
		switch x := v.(type) {
		case uint:
			return x
		case uint64:
			return uint(x)
		case int:
			if x > 0 {
				return uint(x)
			}
		case string:
			if id, err := strconv.ParseUint(x, 10, 64); err == nil {
				return uint(id)
			}
		}
	}
	return 0
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	var req TechnicianProfileReq
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false, "error": err.Error(),
		})
	}

	techID := techIDFromLocals(c)
	if techID == 0 {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false, "error": "unauthorized",
		})
	}

	id, err := h.svc.UpsertProfile(c.Context(), techID, req)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false, "error": err.Error(),
		})
	}

	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "profile updated",
		"data":    fiber.Map{"technician_id": id},
	})
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
	techID := techIDFromLocals(c)
	if techID == 0 {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "unauthorized",
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
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false, "error": "unauthorized",
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
	techID := techIDFromLocals(c)
	if techID == 0 {
		return fiber.NewError(fiber.StatusUnauthorized, "unauthorized")
	}

	var body AddTechServiceReq
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}

	result, err := h.svc.AddService(c.Context(), techID, body)
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "service added to technician",
		"data":    result,
	})
}

func (h *Handler) RemoveService(c fiber.Ctx) error {
	techID := techIDFromLocals(c)
	if techID == 0 {
		return fiber.NewError(fiber.StatusUnauthorized, "unauthorized")
	}

	var body RemoveTechServiceReq
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}
	if body.ProvinceID == 0 || body.ServiceID == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "province_id and service_id are required")
	}

	if err := h.svc.RemoveService(c.Context(), techID, body); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "service removed successfully",
	})
}
