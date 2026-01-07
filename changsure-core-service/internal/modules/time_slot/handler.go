package timeslot

import (
	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) GetTimeSlots(c fiber.Ctx) error {
	slots, err := h.service.GetAllTimeSlots(c.Context())
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"error": "Failed to fetch time slots"})
	}
	return c.JSON(fiber.Map{"success": true, "data": slots})
}

func (h *Handler) GetMyTimeSlots(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	slots, err := h.service.GetMyTimeSlots(c.Context(), techID)
	if err != nil {
		return appErrors.InternalError(c, "failed to get time slots", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": slots})
}

func (h *Handler) UpdateMyTimeSlots(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req UpsertTimeSlotsRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	if err := h.service.UpdateMyTimeSlots(c.Context(), techID, req); err != nil {
		return appErrors.InternalError(c, "failed to update time slots", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "time slots updated"})
}

func (h *Handler) ResetMyTimeSlots(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	if err := h.service.ResetMyTimeSlots(c.Context(), techID); err != nil {
		return appErrors.InternalError(c, "failed to reset time slots", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "reset to default time slots"})
}
