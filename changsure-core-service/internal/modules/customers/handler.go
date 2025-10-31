package customers

import (
	"errors"
	"strconv"

	"changsure-core-service/internal/middleware"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// POST /customers
func (h *Handler) CreateCustomer(c fiber.Ctx) error {
	var req CreateCustomerRequest
	if err := c.Bind().JSON(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
			"error":   err.Error(),
		})
	}
	if err := req.Validate(); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": err.Error(),
		})
	}

	ctx := middleware.GetContext(c)
	customer, err := h.service.CreateCustomer(ctx, &req)
	if err != nil {
		if errors.Is(err, ErrPhoneAlreadyExists) {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Phone number already exists",
			})
		}
		if errors.Is(err, ErrEmailAlreadyExists) {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Email already exists",
			})
		}
		if errors.Is(err, ErrInvalidInput) {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"status":  "error",
				"message": err.Error(),
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to create customer",
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":  "success",
		"message": "Customer created successfully",
		"data":    ToCustomerResponse(customer),
	})
}

// GET /customers/:id
func (h *Handler) GetCustomer(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid customer ID",
		})
	}

	ctx := middleware.GetContext(c)
	customer, err := h.service.GetCustomer(ctx, uint(id))
	if err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Customer not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to get customer",
		})
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToCustomerResponse(customer),
	})
}

// PATCH /customers/:id
func (h *Handler) UpdateCustomer(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid customer ID",
		})
	}

	var req UpdateCustomerRequest
	if err := c.Bind().JSON(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid request body",
		})
	}
	if err := req.Validate(); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": err.Error(),
		})
	}

	ctx := middleware.GetContext(c)
	customer, err := h.service.UpdateCustomer(ctx, uint(id), &req)
	if err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Customer not found",
			})
		}
		if errors.Is(err, ErrPhoneAlreadyExists) {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Phone number already exists",
			})
		}
		if errors.Is(err, ErrEmailAlreadyExists) {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"status":  "error",
				"message": "Email already exists",
			})
		}
		if errors.Is(err, ErrInvalidInput) {
			return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
				"status":  "error",
				"message": err.Error(),
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to update customer",
		})
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Customer updated successfully",
		"data":    ToCustomerResponse(customer),
	})
}

// DELETE /customers/:id
func (h *Handler) DeleteCustomer(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"status":  "error",
			"message": "Invalid customer ID",
		})
	}

	ctx := middleware.GetContext(c)
	if err := h.service.DeleteCustomer(ctx, uint(id)); err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
				"status":  "error",
				"message": "Customer not found",
			})
		}
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to delete customer",
		})
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Customer deleted successfully",
	})
}

// GET /customers 
func (h *Handler) ListCustomers(c fiber.Ctx) error {
	page := c.Query("page", "1")
	pageSize := c.Query("page_size", "20")

	pageInt, _ := strconv.Atoi(page)
	pageSizeInt, _ := strconv.Atoi(pageSize)

	ctx := middleware.GetContext(c)
	customers, err := h.service.ListCustomers(ctx, pageInt, pageSizeInt)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"status":  "error",
			"message": "Failed to list customers",
		})
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