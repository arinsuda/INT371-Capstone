package customers

import (
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v3"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/pkg/utils"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) GetProfile(c fiber.Ctx) error {

	customerID := utils.GetUserID(c)
	if customerID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), customerID)

	customer, err := h.service.GetProfile(ctx, customerID)
	if err != nil {

		if strings.Contains(err.Error(), "not found") {
			return appErrors.NotFound(c, "customer not found")
		}
		return appErrors.InternalError(c, "failed to get profile", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    ToCustomerResponse(customer),
	})
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	customerID := utils.GetUserID(c)
	if customerID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req UpdateCustomerRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), customerID)

	customer, err := h.service.UpdateProfile(ctx, customerID, &req)
	if err != nil {
		switch {
		case err == ErrCustomerNotFound:
			return appErrors.NotFound(c, "customer not found")
		case err == ErrUnauthorizedOwner:
			return appErrors.Forbidden(c, "access denied")
		case err == ErrPhoneAlreadyExists:
			return appErrors.Conflict(c, "phone number already exists")
		case err == ErrEmailAlreadyExists:
			return appErrors.Conflict(c, "email already exists")
		case err == ErrInvalidInput:
			return appErrors.BadRequest(c, err.Error())
		default:
			return appErrors.InternalError(c, "failed to update profile", err)
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "profile updated successfully",
		"data":    ToCustomerResponse(customer),
	})
}

func (h *Handler) GetCustomer(c fiber.Ctx) error {

	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	customer, err := h.service.GetCustomer(c.Context(), id)
	if err != nil {
		if err == ErrCustomerNotFound {
			return appErrors.NotFound(c, "customer not found")
		}
		return appErrors.InternalError(c, "failed to get customer", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    ToCustomerResponse(customer),
	})
}

func (h *Handler) UpdateCustomer(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	var req UpdateCustomerRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	customer, err := h.service.UpdateCustomer(c.Context(), id, &req)
	if err != nil {
		switch {
		case err == ErrCustomerNotFound:
			return appErrors.NotFound(c, "customer not found")
		case err == ErrPhoneAlreadyExists:
			return appErrors.Conflict(c, "phone number already exists")
		case err == ErrEmailAlreadyExists:
			return appErrors.Conflict(c, "email already exists")
		default:
			return appErrors.InternalError(c, "failed to update customer", err)
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "customer updated successfully",
		"data":    ToCustomerResponse(customer),
	})
}

func (h *Handler) DeleteCustomer(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := h.service.DeleteCustomer(c.Context(), id); err != nil {
		if err == ErrCustomerNotFound {
			return appErrors.NotFound(c, "customer not found")
		}
		return appErrors.InternalError(c, "failed to delete customer", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "customer deleted successfully",
	})
}

func (h *Handler) ListCustomers(c fiber.Ctx) error {

	page := 1
	if v := c.Query("page"); v != "" {
		if p, err := strconv.Atoi(v); err == nil && p > 0 {
			page = p
		}
	}

	pageSize := 20
	if v := c.Query("page_size"); v != "" {
		if s, err := strconv.Atoi(v); err == nil && s > 0 {
			pageSize = s
		}
	}

	customers, err := h.service.ListCustomers(c.Context(), page, pageSize)
	if err != nil {
		return appErrors.InternalError(c, "failed to list customers", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"customers": ToCustomerResponseList(customers),
			"page":      page,
			"page_size": pageSize,
			"total":     len(customers),
		},
	})
}
