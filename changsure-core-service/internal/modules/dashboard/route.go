package dashboard

import (
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterAdminRoutes(r fiber.Router) {
	r.Get("/", h.GetDashboard).Use(middleware.AdminOnly())
	r.Get("/pending-verifications", h.GetPendingVerifications)
	r.Get("/categories/:categoryID/services", h.GetServicesByCategory)
	r.Get("/services/:serviceID/technicians", h.GetTechniciansByService)
}
