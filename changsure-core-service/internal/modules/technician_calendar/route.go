package techniciancalendar

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	cal := router.Group("/:technicianID/calendar")

	cal.Get("/:period", h.GetCalendarAuto)                  
	cal.Patch("/", h.UpdateCalendarDate)                     
	cal.Put("/:date/time-slot", h.UpdateTimeSlots)       
}