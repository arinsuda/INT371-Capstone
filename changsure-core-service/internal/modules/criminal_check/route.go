package criminalcheck

import (
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {

	r.Post("/:technicianID/verify-identity", h.VerifyIdentity)
}

func (h *Handler) RegisterAdminRoutes(r fiber.Router) {
	admin := r.Group("/verification").Use(middleware.AdminOnly())

	admin.Get("/stats", h.GetStats)
	admin.Get("/logs", h.ListLogs)
	admin.Get("/logs/technician/:technicianID", h.GetLogsByTechnician)
	admin.Patch("/logs/:logID", h.UpdateLogStatus)
	admin.Patch("/technicians/:technicianID/is-verified", h.OverrideIsVerified)

	admin.Get("/criminal-records", h.ListCriminalRecords)
	admin.Get("/criminal-records/:recordID", h.GetCriminalRecord)
	admin.Post("/criminal-records", h.CreateCriminalRecord)
	admin.Patch("/criminal-records/:recordID", h.UpdateCriminalRecord)
	admin.Delete("/criminal-records/:recordID", h.DeleteCriminalRecord)
}
