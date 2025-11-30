package customer_addresses

import (
	"errors"
	"strconv"

	customErr "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/internal/validation"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) CreateAddress(c fiber.Ctx) error {
	custID, ok := c.Locals("userID").(uint)
	if !ok || custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	var req CreateCustomerAddressRequest
	if err := c.Bind().JSON(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return customErr.ValidationError(c, details)
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.Create(ctx, uint(custID), &req)
	if err != nil {
		return customErr.InternalError(c, "failed to create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) ListAddresses(c fiber.Ctx) error {
	custID, ok := c.Locals("userID").(uint)
	if !ok || custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	ctx := middleware.GetContext(c)
	list, err := h.service.List(ctx, uint(custID))
	if err != nil {
		return customErr.InternalError(c, "failed to fetch addresses", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponseList(list),
	})
}

func (h *Handler) GetAddress(c fiber.Ctx) error {
	custID, ok := c.Locals("userID").(uint)
	if !ok || custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	addrID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return customErr.BadRequest(c, "invalid address id")
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.Get(ctx, uint(addrID), custID)
	if err != nil {
		if errors.Is(err, address_shared.ErrAddressNotFound) {
			return customErr.NotFound(c, "address not found")
		}
		return customErr.InternalError(c, "failed to get address", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) UpdateAddress(c fiber.Ctx) error {
	custID, ok := c.Locals("userID").(uint)
	if !ok || custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	addrIDRaw := c.Params("id")
	addrID, err := strconv.ParseUint(addrIDRaw, 10, 32)
	if err != nil || addrID == 0 {
		return customErr.BadRequest(c, "invalid address id")
	}

	var req UpdateCustomerAddressRequest
	if err := c.Bind().JSON(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return customErr.ValidationError(c, details)
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.Update(ctx, uint(addrID), custID, &req)
	if err != nil {

		switch {
		case errors.Is(err, address_shared.ErrAddressNotFound):
			return customErr.NotFound(c, "address not found")

		case errors.Is(err, address_shared.ErrUnauthorized):
			return customErr.Unauthorized(c, "you do not own this address")

		default:
			return customErr.InternalError(c, "failed to update address", err)
		}
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) DeleteAddress(c fiber.Ctx) error {
	custID, ok := c.Locals("userID").(uint)
	if !ok || custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	addrID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return customErr.BadRequest(c, "invalid address id")
	}

	ctx := middleware.GetContext(c)
	if err := h.service.Delete(ctx, uint(addrID), uint(custID)); err != nil {
		return customErr.InternalError(c, "failed to delete address", err)
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "address deleted",
	})
}

func (h *Handler) SetPrimaryAddress(c fiber.Ctx) error {
	custID, ok := c.Locals("userID").(uint)
	if !ok || custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	addrID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return customErr.BadRequest(c, "invalid address id")
	}
	
	ctx := middleware.GetContext(c)
	if err := h.service.SetPrimary(ctx, uint(addrID), uint(custID)); err != nil {
		return customErr.InternalError(c, "failed to set primary", err)
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "primary address updated",
	})
}

func (h *Handler) SearchNearby(c fiber.Ctx) error {
	var req address_shared.NearbyQuery
	if err := c.Bind().JSON(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	if req.KM <= 0 || req.KM > 100 {
		req.KM = 30
	}

	if req.Limit <= 0 {
		req.Limit = 50
	}

	ctx := middleware.GetContext(c)
	results, err := h.service.NearbyTechnicians(ctx, req)
	if err != nil {
		return customErr.InternalError(c, "failed to search nearby technicians", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   results,
	})
}
