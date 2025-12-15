package customers

import (
	utils "changsure-core-service/pkg/utils"
	"errors"
	"net/http"
	"strconv"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

func customerIDFromLocals(c fiber.Ctx) uint {
	if v := c.Locals("userID"); v != nil {
		switch x := v.(type) {
		case uint:
			return x
		case uint64:
			return uint(x)
		case int:
			if x > 0 {
				return uint(x)
			}
		case string:
			if id, err := strconv.ParseUint(x, 10, 64); err == nil {
				return uint(id)
			}
		}
	}
	return 0
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
	customerID := customerIDFromLocals(c)
	if customerID == 0 {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "unauthorized",
		})
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), customerID)

	customer, err := h.service.GetProfile(ctx, customerID)

	if err != nil {
		if errors.Is(err, ErrAccessDenied) {
			return c.Status(http.StatusForbidden).JSON(fiber.Map{
				"success": false,
				"message": "Access denied",
			})
		}

		if errors.Is(err, ErrCustomerNotFound) {
			return c.Status(http.StatusNotFound).JSON(fiber.Map{
				"success": false,
				"message": "Customer not found",
			})
		}

		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to get profile",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    ToCustomerResponse(customer),
	})
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	customerID := customerIDFromLocals(c)
	if customerID == 0 {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "unauthorized",
		})
	}

	var req UpdateCustomerRequest
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid request body",
		})
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), customerID)

	customer, err := h.service.UpdateProfile(ctx, customerID, &req)
	if err != nil {
		switch {
		case errors.Is(err, ErrCustomerNotFound):
			return c.Status(http.StatusNotFound).JSON(fiber.Map{"success": false, "message": "Customer not found"})

		case errors.Is(err, ErrUnauthorizedOwner):
			return c.Status(http.StatusForbidden).JSON(fiber.Map{"success": false, "message": "Forbidden: Access denied"})

		case errors.Is(err, ErrPhoneAlreadyExists):
			return c.Status(http.StatusConflict).JSON(fiber.Map{"success": false, "message": "Phone number already exists"})
		case errors.Is(err, ErrEmailAlreadyExists):
			return c.Status(http.StatusConflict).JSON(fiber.Map{"success": false, "message": "Email already exists"})
		case errors.Is(err, ErrInvalidInput):
			return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "message": err.Error()})
		default:
			return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"success": false, "message": "Failed to update profile"})
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Profile updated successfully",
		"data":    ToCustomerResponse(customer),
	})
}

func (h *Handler) GetCustomer(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid customer ID",
		})
	}

	customer, err := h.service.GetCustomer(c.Context(), uint(id))
	if err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return c.Status(http.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Customer not found",
			})
		}
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to get customer",
		})
	}

	return c.JSON(fiber.Map{"status": "success", "data": ToCustomerResponse(customer)})
}

func (h *Handler) UpdateCustomer(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"status": "error", "message": "Invalid customer ID"})
	}

	var req UpdateCustomerRequest
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"status": "error", "message": "Invalid request body"})
	}

	customer, err := h.service.UpdateCustomer(c.Context(), uint(id), &req)
	if err != nil {
		switch {
		case errors.Is(err, ErrCustomerNotFound):
			return c.Status(http.StatusNotFound).JSON(fiber.Map{"status": "error", "message": "Customer not found"})
		case errors.Is(err, ErrPhoneAlreadyExists):
			return c.Status(http.StatusConflict).JSON(fiber.Map{"status": "error", "message": "Phone number already exists"})
		case errors.Is(err, ErrEmailAlreadyExists):
			return c.Status(http.StatusConflict).JSON(fiber.Map{"status": "error", "message": "Email already exists"})
		default:
			return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"status": "error", "message": "Failed to update customer"})
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Customer updated successfully",
		"data":    ToCustomerResponse(customer),
	})
}

func (h *Handler) DeleteCustomer(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"status": "error", "message": "Invalid customer ID"})
	}

	if err := h.service.DeleteCustomer(c.Context(), uint(id)); err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return c.Status(http.StatusNotFound).JSON(fiber.Map{"status": "error", "message": "Customer not found"})
		}
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"status": "error", "message": "Failed to delete customer"})
	}

	return c.JSON(fiber.Map{"status": "success", "message": "Customer deleted successfully"})
}

func (h *Handler) ListCustomers(c fiber.Ctx) error {
	page := c.Query("page", "1")
	pageSize := c.Query("page_size", "20")

	pageInt, _ := strconv.Atoi(page)
	pageSizeInt, _ := strconv.Atoi(pageSize)

	customers, err := h.service.ListCustomers(c.Context(), pageInt, pageSizeInt)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"status": "error", "message": "Failed to list customers"})
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data": fiber.Map{
			"customers": ToCustomerResponseList(customers),
			"page":      pageInt,
			"page_size": pageSizeInt,
			"total":     len(customers),
		},
	})
}
