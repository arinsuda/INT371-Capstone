package customerbooking

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	group := router.Group("/bookings")

	group.Post("/", h.CreateBooking)
	group.Get("/", h.ListBookings)
	group.Get("/availability", h.CheckAvailability)
	group.Get("/:id", h.GetBookingDetail)
	group.Patch("/:id/cancel", h.CancelBooking)
}
