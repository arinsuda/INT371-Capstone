package customeraddresses

import (
	"strconv"

	"changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/validation"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler { return &Handler{service: s} }

func (h *Handler) CreateAddress(c fiber.Ctx) error {
	custID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return errors.BadRequest(c, "Invalid customer ID")
	}

	var req CreateCustomerAddressRequest
	if err := decodeJSON(c, &req); err != nil {
		return errors.BadRequest(c, "Invalid request body", []validation.FieldError{{Field: "body", Error: err.Error()}})
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return errors.ValidationError(c, details)
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.CreateAddress(ctx, uint(custID), &req)
	if err != nil {
		return errors.InternalError(c, "Failed to create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) ListAddresses(c fiber.Ctx) error {
	custID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return errors.BadRequest(c, "Invalid customer ID")
	}

	ctx := middleware.GetContext(c)
	list, err := h.service.ListAddresses(ctx, uint(custID))
	if err != nil {
		return errors.InternalError(c, "Failed to list addresses", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponseList(list),
	})
}

func (h *Handler) GetAddress(c fiber.Ctx) error {
	addrID, err := strconv.ParseUint(c.Params("addrId"), 10, 32)
	if err != nil {
		return errors.BadRequest(c, "Invalid address ID")
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.GetAddress(ctx, uint(addrID))
	if err != nil {
		return errors.InternalError(c, "Failed to get address", err)
	}
	if addr == nil {
		return errors.NotFound(c, "Address not found")
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) UpdateAddress(c fiber.Ctx) error {
	addrID, err := strconv.ParseUint(c.Params("addrId"), 10, 32)
	if err != nil {
		return errors.BadRequest(c, "Invalid address ID")
	}

	var req UpdateCustomerAddressRequest
	if err := decodeJSON(c, &req); err != nil {
		return errors.BadRequest(c, "Invalid request body", []validation.FieldError{{Field: "body", Error: err.Error()}})
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return errors.ValidationError(c, details)
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.UpdateAddress(ctx, uint(addrID), &req)
	if err != nil {
		return errors.InternalError(c, "Failed to update address", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) DeleteAddress(c fiber.Ctx) error {
	addrID, err := strconv.ParseUint(c.Params("addrId"), 10, 32)
	if err != nil {
		return errors.BadRequest(c, "Invalid address ID")
	}

	ctx := middleware.GetContext(c)
	if err := h.service.DeleteAddress(ctx, uint(addrID)); err != nil {
		return errors.InternalError(c, "Failed to delete address", err)
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "Address deleted successfully",
	})
}
