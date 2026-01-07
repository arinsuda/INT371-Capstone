package technicianschedule

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	group := router.Group("/schedule")

	group.Get("/weekly", h.GetWeeklySchedule)
	group.Put("/weekly", h.UpdateWeeklySchedule)

	group.Post("/leaves", h.AddLeaveDate)
	group.Delete("/leaves", h.RemoveLeaveDate)
}
