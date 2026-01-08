package booking

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {

	group := router.Group("/bookings")

	group.Post("/", h.CreateBooking)
	group.Get("/availability", h.CheckAvailability)
	group.Get("/:id", h.GetBookingDetail)
}

func (h *Handler) RegisterTechnicianRoutes(router fiber.Router) {

	group := router.Group("/bookings")

	group.Get("/", h.ListTechnicianBookings)
	group.Patch("/:id/accept", h.AcceptBooking)
	group.Patch("/:id/reject", h.RejectBooking)
}
