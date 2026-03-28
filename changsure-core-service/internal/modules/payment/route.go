package payment

import (
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(api fiber.Router) {
	payments := api.Group("/payments")
	payments.Post("/", h.CreatePayment)
	payments.Get("/:paymentID", h.GetPayment)
	if h.isTestMode {
		payments.Post("/simulations", h.SimulatePayment)
	}
	bookings := api.Group("/bookings")
	bookings.Get("/:booking_id/payments", h.GetPaymentsByBooking)
	bookings.Get("/:booking_id/payments/status", h.GetPaymentStatusByBooking)
	bookings.Delete("/:booking_id/payments/pending", h.CancelPendingPayment)
	bookings.Patch("/:booking_id/payments/status", middleware.AdminOnly(), h.UpdatePaymentStatus)
}

func (h *Handler) RegisterWebhookRoutes(api fiber.Router) {
	webhooks := api.Group("/webhooks")
	webhooks.Post("/omise", h.OmiseWebhook)
}
