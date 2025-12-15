package customeraddress

import (
	"errors"
	"strconv"

	customErr "changsure-core-service/internal/errors"
	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/internal/validation"

	"changsure-core-service/pkg/utils"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) CreateCustomerAddress(c fiber.Ctx) error {
	custID := extractCustomerID(c)
	if custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	var req CreateCustomerAddressRequest
	if err := c.Bind().JSON(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return customErr.ValidationError(c, details)
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	addr, err := h.service.CreateCustomerAddress(ctx, custID, &req)
	if err != nil {
		return customErr.InternalError(c, "failed to create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) ListCustomerAddresses(c fiber.Ctx) error {
	custID := extractCustomerID(c)
	if custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	list, err := h.service.ListCustomerAddresses(ctx, custID)
	if err != nil {
		return customErr.InternalError(c, "failed to fetch addresses", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponseList(list),
	})
}

func (h *Handler) GetCustomerAddress(c fiber.Ctx) error {
	custID := extractCustomerID(c)
	if custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	addrID, err := parseIDParam(c, "id")
	if err != nil {
		return customErr.BadRequest(c, "invalid address id")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	addr, err := h.service.GetCustomerAddress(ctx, addrID, custID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return customErr.NotFound(c, "address not found")
		}

		if errors.Is(err, addressshared.ErrUnauthorized) {
			return customErr.Forbidden(c, "access denied")
		}

		return customErr.InternalError(c, "failed to get address", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) UpdateCustomerAddress(c fiber.Ctx) error {
	custID := extractCustomerID(c)
	if custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	addrID, err := parseIDParam(c, "id")
	if err != nil {
		return customErr.BadRequest(c, "invalid address id")
	}

	var req UpdateCustomerAddressRequest
	if err := c.Bind().Body(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return customErr.ValidationError(c, details)
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	addr, err := h.service.UpdateCustomerAddress(ctx, addrID, custID, &req)
	if err != nil {
		switch {
		case errors.Is(err, addressshared.ErrAddressNotFound):
			return customErr.NotFound(c, "address not found")
		case errors.Is(err, addressshared.ErrUnauthorized):
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

func (h *Handler) DeleteCustomerAddress(c fiber.Ctx) error {
	custID := extractCustomerID(c)
	if custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	addrID, err := parseIDParam(c, "id")
	if err != nil {
		return customErr.BadRequest(c, "invalid address id")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	if err := h.service.DeleteCustomerAddress(ctx, addrID, custID); err != nil {
		switch {
		case errors.Is(err, ErrNotFound):
			return customErr.NotFound(c, "address not found")

		case errors.Is(err, ErrCannotDeletePrimary):
			return customErr.BadRequest(c, "cannot delete primary address")

		case errors.Is(err, addressshared.ErrUnauthorized):
			return customErr.Forbidden(c, "access denied")

		default:
			return customErr.InternalError(c, "failed to delete address", err)
		}
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "address deleted",
	})
}

func (h *Handler) SetPrimaryCustomerAddress(c fiber.Ctx) error {
	custID := extractCustomerID(c)
	if custID == 0 {
		return customErr.BadRequest(c, "invalid customer token")
	}

	addrID, err := parseIDParam(c, "id")
	if err != nil {
		return customErr.BadRequest(c, "invalid address id")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	if err := h.service.SetPrimaryCustomerAddress(ctx, addrID, custID); err != nil {
		return customErr.InternalError(c, "failed to set primary address", err)
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "primary address updated",
	})
}

func (h *Handler) SearchNearbyTechnicians(c fiber.Ctx) error {
	var req addressshared.NearbyQuery
	if err := c.Bind().JSON(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	if req.KM <= 0 || req.KM > 100 {
		req.KM = 30
	}
	if req.Limit <= 0 {
		req.Limit = 50
	}

	ctx := c.Context()

	results, err := h.service.SearchNearbyTechnicians(ctx, req)
	if err != nil {
		return customErr.InternalError(c, "failed to search technicians", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   results,
	})
}

func extractCustomerID(c fiber.Ctx) uint {
	id, _ := c.Locals("userID").(uint)
	return id
}

func parseIDParam(c fiber.Ctx, key string) (uint, error) {
	raw := c.Params(key)
	id, err := strconv.ParseUint(raw, 10, 32)
	return uint(id), err
}
