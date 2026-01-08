package technicianschedule

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

func (h *Handler) UpdateWeeklySchedule(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req UpdateWeeklyScheduleRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	if err := h.service.UpdateWeeklySchedule(c.Context(), techID, req); err != nil {
		return appErrors.InternalError(c, "failed to update schedule", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "weekly schedule updated"})
}

func (h *Handler) GetWeeklySchedule(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	days, err := h.service.GetWeeklySchedule(c.Context(), techID)
	if err != nil {
		return appErrors.InternalError(c, "failed to get schedule", err)
	}

	if len(days) == 0 {

	}

	return c.JSON(fiber.Map{"success": true, "data": days})
}

func (h *Handler) AddLeaveDate(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req CreateLeaveRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	if err := h.service.AddLeaveDate(c.Context(), techID, req); err != nil {
		return appErrors.InternalError(c, "failed to add leave date", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "leave date added"})
}

func (h *Handler) RemoveLeaveDate(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req DeleteLeaveRequest
	if err := c.Bind().Query(&req); err != nil {
		return appErrors.BadRequest(c, "invalid query params")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	if err := h.service.RemoveLeaveDate(c.Context(), techID, req.Date); err != nil {
		return appErrors.InternalError(c, "failed to remove leave date", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "leave date removed"})
}
