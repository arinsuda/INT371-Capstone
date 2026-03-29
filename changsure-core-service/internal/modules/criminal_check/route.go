package criminalcheck

import (
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router, secretKey string) {
	r.Post("/:technicianID/identity-verifications",
		middleware.PreVerifiedAuth(secretKey),
		h.VerifyIdentity,
	)
	r.Get("/identity-verifications/:jobID",
		h.GetJobStatus,
	)
}

func (h *Handler) RegisterAdminRoutes(r fiber.Router) {
	r.Get("/stats", h.GetStats)
	r.Get("/logs", h.ListLogs)
	r.Get("/logs/technician/:technicianID", h.GetLogsByTechnician)
	r.Patch("/logs/:logID", h.UpdateLogStatus)
	r.Get("/technicians/:technicianID/verification-detail", h.GetVerificationDetail)
	r.Patch("/technicians/:technicianID/verification-status", h.OverrideVerificationStatus)
	r.Get("/jobs", h.ListPendingManualJobs)
	r.Post("/jobs/:jobID/approve", h.ApproveJob)
	r.Post("/jobs/:jobID/reject", h.RejectJob)
	r.Get("/criminal-records", h.ListCriminalRecords)
	r.Get("/criminal-records/:recordID", h.GetCriminalRecord)
	r.Post("/criminal-records", h.CreateCriminalRecord)
	r.Patch("/criminal-records/:recordID", h.UpdateCriminalRecord)
	r.Delete("/criminal-records/:recordID", h.DeleteCriminalRecord)
}
