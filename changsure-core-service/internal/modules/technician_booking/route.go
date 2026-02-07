package technicianbooking

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	group := router.Group("/bookings")

	group.Get("/", h.ListBookings)
	group.Get("/:id", h.GetBooking)
	group.Patch("/:id/accept", h.AcceptBooking)
	group.Patch("/:id/reject", h.RejectBooking)
	group.Patch("/:id/start", h.StartJob)
	group.Patch("/:id/complete", h.CompleteJob)
}
