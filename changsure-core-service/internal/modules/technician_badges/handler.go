package technician_badges

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

func (h *Handler) Assign(c fiber.Ctx) error {
	technicianID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}

	var body struct {
		BadgeID   uint       `json:"badge_id"`
		ExpiredAt *time.Time `json:"expired_at"`
	}
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	tb, err := h.svc.AssignBadge(ctx, technicianID, body.BadgeID, body.ExpiredAt)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusCreated).JSON(tb)
}

func (h *Handler) ListByTechnician(c fiber.Ctx) error {
	technicianID, err := utils.ParseUintParam(c, "technician_id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	items, err := h.svc.GetBadgesByTechnician(ctx, technicianID)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(items)
}

func (h *Handler) Remove(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid id")
	}

	hard := c.Query("hard") == "true"

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := h.svc.RemoveBadge(ctx, id, hard); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.SendStatus(fiber.StatusNoContent)
}
