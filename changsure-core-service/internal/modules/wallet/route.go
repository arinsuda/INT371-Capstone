package wallet

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {

	router.Get("/:technicianID/wallet", h.GetBalance)
	router.Get("/:technicianID/wallet/summary", h.GetSummary)
	router.Get("/:technicianID/wallet/transactions", h.ListTransactions)
	router.Get("/:technicianID/wallet/withdrawals", h.ListWithdrawals)
	router.Post("/:technicianID/wallet/withdraw", h.Withdraw)
}
