package technicianmatching

import (
	"errors"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	technician "changsure-core-service/internal/modules/technician"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc      Service
	adminSvc technician.Service
}

func NewHandler(s Service, adminSvc technician.Service) *Handler {
	return &Handler{
		svc:      s,
		adminSvc: adminSvc,
	}
}

func (h *Handler) ListTechnicians(c fiber.Ctx) error {
	role, _ := middleware.GetRole(c)
	userID, _ := middleware.GetUserID(c)

	if role == "admin" {
		var q technician.AdminListQuery
		if err := c.Bind().Query(&q); err != nil {
			return appErrors.BadRequest(c, "invalid query parameters")
		}
		q.SetDefaults()

		resp, err := h.adminSvc.ListWithFilter(c.Context(), q)
		if err != nil {
			return appErrors.InternalError(c, "failed to list technicians", err)
		}

		return c.JSON(fiber.Map{
			"success": true,
			"data":    resp,
		})
	}

	if userID == 0 {
		return appErrors.Unauthorized(c, ErrUnauthorized.Error())
	}

	var q TechnicianSearchQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, ErrInvalidInput.Error())
	}
	q.SetDefaults()

	result, err := h.svc.ListTechnicians(c.Context(), userID, q)
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    result,
	})
}

func (h *Handler) AutoSelectTechnician(c fiber.Ctx) error {
	customerID, ok := middleware.GetUserID(c)
	if customerID == 0 || !ok {
		return appErrors.Unauthorized(c, ErrUnauthorized.Error())
	}

	var req AutoSelectRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, ErrInvalidInput.Error())
	}
	if req.ServiceID == 0 || req.ProvinceID == 0 {
		return appErrors.BadRequest(c, "service_id and province_id are required")
	}

	res, err := h.svc.AutoSelectTechnician(c.Context(), customerID, req)
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) handleServiceError(c fiber.Ctx, err error) error {
	switch {
	case errors.Is(err, ErrTechnicianNotFound):
		return appErrors.NotFound(c, err.Error())
	case errors.Is(err, ErrNoCustomerAddress):
		return appErrors.BadRequest(c, err.Error())
	case errors.Is(err, ErrNoTechnicianFound):
		return appErrors.NotFound(c, err.Error())
	default:
		return appErrors.InternalError(c, "something went wrong", err)
	}
}
