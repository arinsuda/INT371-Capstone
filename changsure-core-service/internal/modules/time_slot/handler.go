package timeslot

import (
	appErrors "changsure-core-service/internal/errors"

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
		return appErrors.InternalError(c, "failed to fetch time slots", err)
	}
	return c.JSON(fiber.Map{"success": true, "data": slots})
}
