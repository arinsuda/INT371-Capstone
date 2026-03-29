package customerreview

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Post("/:customerID/bookings/:bookingID/reviews", h.CreateReview)
}
