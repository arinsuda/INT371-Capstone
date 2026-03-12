package payment

import (
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(api fiber.Router) {
	paymentGroup := api.Group("/payments")

	paymentGroup.Post("/qr", h.GenerateQR)
	paymentGroup.Get("/sources/:source_id", h.GetPaymentSource)
	paymentGroup.Get("/bookings/:booking_id/history", h.GetPaymentHistory)
	paymentGroup.Get("/bookings/:booking_id/status", h.CheckPaymentStatus)

	paymentGroup.Post("/confirm", middleware.AdminOnly(), h.ConfirmPayment)

	if h.isTestMode {
		paymentGroup.Post("/test/simulate-success", h.SimulatePaymentSuccess)
	}
}

func (h *Handler) RegisterWebhookRoutes(api fiber.Router) {

	api.Post("/payments/webhook", h.OmiseWebhook)
}
