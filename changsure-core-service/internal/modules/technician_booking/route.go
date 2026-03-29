package technicianbooking

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	group := router.Group("/:technicianID/bookings")

	group.Get("/", h.ListBookings)
	group.Get("/:bookingID", h.GetBooking)
	group.Patch("/:bookingID", h.UpdateBookingStatus)
}
