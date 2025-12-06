package technicianbadge

import (
	"context"
	"errors"
	"time"

	appErr "changsure-core-service/internal/errors"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc Service }

func NewHandler(svc Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) Assign(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil {
		return appErr.BadRequest(c, "invalid technician id")
	}

	var req AssignBadgeRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErr.BadRequest(c, "invalid request body")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	tb, err := h.svc.AssignBadge(ctx, techID, req.BadgeID, req.ExpiredAt)
	if err != nil {
		if errors.Is(err, ErrTechnicianNotFound) {
			return appErr.NotFound(c, "technician not found")
		}
		return appErr.InternalError(c, "failed to assign badge", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    toResponse(tb),
	})
}

func (h *Handler) ListByTechnician(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil {
		return appErr.BadRequest(c, "invalid technician id")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	items, err := h.svc.GetBadgesByTechnician(ctx, techID)
	if err != nil {
		return appErr.InternalError(c, "failed to fetch badges", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    toResponses(items),
	})
}

func (h *Handler) Unassign(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil {
		return appErr.BadRequest(c, "invalid technician id")
	}

	badgeID, err := utils.ParseUintParam(c, "badge_id")
	if err != nil {
		return appErr.BadRequest(c, "invalid badge id")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	if err := h.svc.RemoveBadge(ctx, techID, badgeID); err != nil {
		return appErr.InternalError(c, "failed to remove badge", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "badge removed",
	})
}
