package wallet

import (
	"strconv"
	"strings"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/pkg/utils"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	repo      Repository
	service   Service
	techRepo  technician.Repository
	validator *validator.Validate
}

func NewHandler(repo Repository, service Service, techRepo technician.Repository) *Handler {
	return &Handler{
		repo:      repo,
		service:   service,
		techRepo:  techRepo,
		validator: validator.New(),
	}
}

func (h *Handler) GetSummary(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	tech, err := h.techRepo.FindByID(c.Context(), techID)
	if err != nil || tech == nil {
		return appErrors.NotFound(c, "technician not found")
	}

	summary, err := h.service.GetSummary(c.Context(), techID, TechInfo{
		TotalJobs: tech.TotalJobs,
		RatingAvg: tech.RatingAvg,
	})
	if err != nil {
		return appErrors.InternalError(c, "failed to get wallet summary", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": summary})
}

func (h *Handler) GetBalance(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	resp, err := h.service.GetBalance(c.Context(), techID)
	if err != nil {
		return appErrors.InternalError(c, "failed to get wallet", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) ListTransactions(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	page, _ := strconv.Atoi(c.Query("page", "1"))
	limit, _ := strconv.Atoi(c.Query("limit", "20"))

	txns, total, err := h.repo.ListTransactions(c.Context(), techID, page, limit)
	if err != nil {
		return appErrors.InternalError(c, "failed to list transactions", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items": txns,
			"meta": fiber.Map{
				"page":  page,
				"limit": limit,
				"total": total,
			},
		},
	})
}

func (h *Handler) ListWithdrawals(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	page, _ := strconv.Atoi(c.Query("page", "1"))
	limit, _ := strconv.Atoi(c.Query("limit", "20"))

	items, total, err := h.repo.ListWithdrawals(c.Context(), techID, page, limit)
	if err != nil {
		return appErrors.InternalError(c, "failed to list withdrawals", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items": items,
			"meta": fiber.Map{
				"page":  page,
				"limit": limit,
				"total": total,
			},
		},
	})
}

func (h *Handler) Withdraw(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var req WithdrawRequest
	if err := c.Bind().JSON(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if err := h.validator.Struct(req); err != nil {
		return appErrors.BadRequest(c, formatValidationError(err))
	}

	result, err := h.service.Withdraw(c.Context(), techID, req)
	if err != nil {
		if strings.Contains(err.Error(), "insufficient balance") {
			return appErrors.BadRequest(c, err.Error())
		}
		return appErrors.InternalError(c, "withdrawal failed", err)
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": result.Message,
		"data": fiber.Map{
			"transaction":   result.Transaction,
			"balance_after": result.BalanceAfter,
		},
	})
}

func formatValidationError(err error) string {
	validationErrs, ok := err.(validator.ValidationErrors)
	if !ok {
		return "validation failed"
	}
	for _, e := range validationErrs {
		switch e.Tag() {
		case "required":
			return e.Field() + " is required"
		case "gt":
			return e.Field() + " must be greater than " + e.Param()
		case "max":
			return e.Field() + " is too long"
		}
	}
	return "validation failed"
}
