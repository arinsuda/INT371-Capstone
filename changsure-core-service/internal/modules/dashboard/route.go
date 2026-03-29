package dashboard

import (
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterAdminRoutes(r fiber.Router) {
	dash := r.Group("/dashboard").Use(middleware.AdminOnly())
	dash.Get("/", h.GetDashboard)
	dash.Get("/pending-verifications", h.GetPendingVerifications)
	dash.Get("/categories/:categoryID/services", h.GetServicesByCategory)
	dash.Get("/services/:serviceID/technicians", h.GetTechniciansByService)
}
