package wallet

import (
	"errors"
	"net/http"
	"strconv"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	repo     Repository
	service  Service
	techRepo technician.Repository
}

func NewHandler(repo Repository, service Service, techRepo technician.Repository) *Handler {
	return &Handler{
		repo:     repo,
		service:  service,
		techRepo: techRepo,
	}
}

func (h *Handler) parseTechID(c fiber.Ctx) (uint, error) {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return 0, appErrors.NewBadRequest("invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return 0, err
	}
	return techID, nil
}

func (h *Handler) GetBalance(c fiber.Ctx) error {
	techID, err := h.parseTechID(c)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	resp, err := h.service.GetBalance(c.Context(), techID)
	if err != nil {
		return appErrors.InternalError(c, "failed to get wallet", err)
	}

	return c.Status(http.StatusOK).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetSummary(c fiber.Ctx) error {
	techID, err := h.parseTechID(c)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	stats, err := h.techRepo.GetStats(c.Context(), techID)
	if err != nil || stats == nil {
		return appErrors.NotFound(c, "technician not found")
	}

	summary, err := h.service.GetSummary(c.Context(), techID, TechInfo{
		TotalJobs: stats.TotalJobs, 
		RatingAvg: stats.RatingAvg,
	})
	if err != nil {
		return appErrors.InternalError(c, "failed to get wallet summary", err)
	}

	return c.Status(http.StatusOK).JSON(fiber.Map{"success": true, "data": summary})
}

func (h *Handler) ListTransactions(c fiber.Ctx) error {
	techID, err := h.parseTechID(c)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	var q ListTransactionsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query parameters")
	}
	if details, err := validation.ValidateStruct(q); err != nil {
		return appErrors.ValidationError(c, details)
	}

	txns, total, err := h.repo.ListTransactions(c.Context(), techID, q)
	if err != nil {
		return appErrors.InternalError(c, "failed to list transactions", err)
	}

	page, limit := normalizePagination(q.Page, q.Limit)
	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"data": PaginatedTransactions{
			Items: txns,
			Meta: PaginationMeta{
				Page:  page,
				Limit: limit,
				Total: total,
			},
		},
	})
}

func (h *Handler) ListWithdrawals(c fiber.Ctx) error {
	techID, err := h.parseTechID(c)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	page, _ := strconv.Atoi(c.Query("page", "1"))
	limit, _ := strconv.Atoi(c.Query("limit", "20"))

	items, total, err := h.repo.ListWithdrawals(c.Context(), techID, page, limit)
	if err != nil {
		return appErrors.InternalError(c, "failed to list withdrawals", err)
	}

	page, limit = normalizePagination(page, limit)
	return c.Status(http.StatusOK).JSON(fiber.Map{
		"success": true,
		"data": PaginatedWithdrawals{
			Items: items,
			Meta: PaginationMeta{
				Page:  page,
				Limit: limit,
				Total: total,
			},
		},
	})
}

func (h *Handler) CreateWithdrawal(c fiber.Ctx) error {
	techID, err := h.parseTechID(c)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	var req WithdrawRequest
	if err := c.Bind().JSON(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	result, err := h.service.Withdraw(c.Context(), techID, req)
	if err != nil {
		return h.handleServiceError(c, err)
	}

	return c.Status(http.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": result.Message,
		"data": fiber.Map{
			"withdrawal":    result.Withdrawal,
			"transaction":   result.Transaction,
			"balance_after": result.BalanceAfter,
		},
	})
}

func (h *Handler) handleServiceError(c fiber.Ctx, err error) error {
	switch {
	case errors.Is(err, ErrInsufficientBalance):
		return appErrors.BadRequest(c, err.Error())
	case errors.Is(err, ErrWithdrawAmountTooLow):
		return appErrors.BadRequest(c, err.Error())
	case errors.Is(err, ErrWithdrawAmountTooHigh):
		return appErrors.BadRequest(c, err.Error())
	case errors.Is(err, ErrDailyLimitExceeded):
		return appErrors.BadRequest(c, err.Error())
	case errors.Is(err, ErrWalletFrozen):
		return appErrors.Forbidden(c, err.Error())
	default:
		return appErrors.InternalError(c, "withdrawal failed", err)
	}
}
