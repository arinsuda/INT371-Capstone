package wallet

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	w := router.Group("/:technicianID/wallet")
	w.Get("/", h.GetBalance)
	w.Get("/summary", h.GetSummary)
	w.Get("/transactions", h.ListTransactions)
	w.Get("/withdrawals", h.ListWithdrawals)
	w.Post("/withdrawals", h.CreateWithdrawal)
}
