package techniciancalendar

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

func (h *Handler) GetTechnicianCalendar(c fiber.Ctx) error {
	var query CalendarQuery
	if err := c.Bind().Query(&query); err != nil {
		return appErrors.BadRequest(c, "invalid query parameters")
	}

	// Validate ง่ายๆ (หรือจะใช้ Validator lib ก็ได้)
	if query.TechnicianID == 0 || query.Month == "" {
		return appErrors.BadRequest(c, "technician_id and month are required")
	}

	result, err := h.service.GetMonthlyCalendar(c.Context(), query)
	if err != nil {
		return appErrors.InternalError(c, "failed to get calendar", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}
