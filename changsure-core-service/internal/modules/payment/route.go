package payment

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	paymentGroup := api.Group("/payments")

	paymentGroup.Post("/qr", h.GenerateQR)
	paymentGroup.Post("/confirm", h.ConfirmPayment)
	paymentGroup.Get("/sources/:source_id", h.GetPaymentSource)

	paymentGroup.Get("/bookings/:booking_id/history", h.GetPaymentHistory)
	paymentGroup.Get("/bookings/:booking_id/status", h.CheckPaymentStatus)

	if h.isTestMode {
		paymentGroup.Post("/test/simulate-success", h.SimulatePaymentSuccess)
	}
}

func (h *Handler) RegisterWebhookRoutes(api fiber.Router) {
	api.Post("/payments/webhook", h.OmiseWebhook)
}
