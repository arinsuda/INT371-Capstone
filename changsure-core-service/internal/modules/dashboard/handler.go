package dashboard

import (
	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc Service }

func NewHandler(svc Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) GetDashboard(c fiber.Ctx) error {
	var q DashboardQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query")
	}
	q.SetDefaults()

	resp, err := h.svc.GetDashboard(c.Context(), q)
	if err != nil {
		return appErrors.InternalError(c, "failed to get dashboard", err)
	}
	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetPendingVerifications(c fiber.Ctx) error {
	var q PendingVerificationQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query")
	}
	q.SetDefaults()

	resp, err := h.svc.GetPendingVerifications(c.Context(), q)
	if err != nil {
		return appErrors.InternalError(c, "failed to get pending verifications", err)
	}
	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetServicesByCategory(c fiber.Ctx) error {
	categoryID, err := utils.ParseUintParam(c, "categoryID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid category id")
	}

	resp, err := h.svc.GetServicesByCategory(c.Context(), categoryID)
	if err != nil {
		return appErrors.NotFound(c, "category not found")
	}
	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetTechniciansByService(c fiber.Ctx) error {
	serviceID, err := utils.ParseUintParam(c, "serviceID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid service id")
	}

	var q ServiceTechQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query")
	}
	q.SetDefaults()

	resp, err := h.svc.GetTechniciansByService(c.Context(), serviceID, q)
	if err != nil {
		return appErrors.InternalError(c, "failed to get technicians", err)
	}
	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetActionItems(c fiber.Ctx) error {
	items, err := h.svc.GetActionItems(c.Context())
	if err != nil {
		return appErrors.InternalError(c, "failed to get action items", err)
	}
	return c.JSON(fiber.Map{"success": true, "data": items})
}
