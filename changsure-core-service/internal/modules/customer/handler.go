package customers

import (
	"errors"
	"strconv"

	"github.com/gofiber/fiber/v3"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/utils"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
	id := utils.GetUserID(c)
	if id == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), id)

	resp, err := h.service.GetProfile(ctx, id)
	if err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return appErrors.NotFound(c, "profile not found")
		}
		return appErrors.InternalError(c, "failed to get profile", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	id := utils.GetUserID(c)
	if id == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req UpdateCustomerRequest

	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), id)

	resp, err := h.service.UpdateProfile(ctx, id, &req)
	if err != nil {
		switch {
		case errors.Is(err, ErrCustomerNotFound):
			return appErrors.NotFound(c, "profile not found")
		case errors.Is(err, ErrPhoneAlreadyExists):
			return appErrors.Conflict(c, "phone number already in use")
		case errors.Is(err, ErrEmailAlreadyExists):
			return appErrors.Conflict(c, "email already in use")
		default:
			return appErrors.InternalError(c, "failed to update profile", err)
		}
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetCustomer(c fiber.Ctx) error {

	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	resp, err := h.service.GetByID(c.Context(), id)
	if err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return appErrors.NotFound(c, "customer not found")
		}
		return appErrors.InternalError(c, "failed to get customer", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) ListCustomers(c fiber.Ctx) error {

	pageStr := c.Query("page")
	pageSizeStr := c.Query("page_size")

	page := 1
	pageSize := 20

	if pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	if pageSizeStr != "" {
		if s, err := strconv.Atoi(pageSizeStr); err == nil && s > 0 {
			pageSize = s
		}
	}

	list, err := h.service.List(c.Context(), page, pageSize)
	if err != nil {
		return appErrors.InternalError(c, "failed to list customers", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"customers": list,
			"page":      page,
			"total":     len(list),
		},
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

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	ctx := c.Context()
	resp, err := h.service.Update(ctx, id, &req)

	if err != nil {
		switch {
		case errors.Is(err, ErrCustomerNotFound):
			return appErrors.NotFound(c, "customer not found")
		case errors.Is(err, ErrPhoneAlreadyExists):
			return appErrors.Conflict(c, "phone number already in use")
		case errors.Is(err, ErrEmailAlreadyExists):
			return appErrors.Conflict(c, "email already in use")
		default:
			return appErrors.InternalError(c, "failed to update customer", err)
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "customer updated successfully",
		"data":    resp,
	})
}

func (h *Handler) DeleteCustomer(c fiber.Ctx) error {

	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	ctx := c.Context()
	if err := h.service.Delete(ctx, id); err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return appErrors.NotFound(c, "customer not found")
		}

		return appErrors.InternalError(c, "failed to delete customer", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "customer deleted successfully",
	})
}
