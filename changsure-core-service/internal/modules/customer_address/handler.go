package customeraddress

import (
	"errors"

	"github.com/gofiber/fiber/v3"

	appErrors "changsure-core-service/internal/errors"
	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/utils"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) Create(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	if custID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req CreateCustomerAddressRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	resp, err := h.service.Create(ctx, custID, &req)
	if err != nil {
		if errors.Is(err, addressshared.ErrInvalidLocation) {
			return appErrors.BadRequest(c, err.Error())
		}
		return appErrors.InternalError(c, "failed to create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) List(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	if custID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	list, err := h.service.List(ctx, custID)
	if err != nil {
		return appErrors.InternalError(c, "failed to list addresses", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": list})
}

func (h *Handler) Get(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	id, err := utils.ParseUintParam(c, "id")
	if err != nil || custID == 0 {
		return appErrors.BadRequest(c, "invalid id or token")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	resp, err := h.service.Get(ctx, id, custID)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			return appErrors.NotFound(c, "address not found")
		}
		return appErrors.InternalError(c, "failed to get address", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Update(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	id, err := utils.ParseUintParam(c, "id")
	if err != nil || custID == 0 {
		return appErrors.BadRequest(c, "invalid id or token")
	}

	var req UpdateCustomerAddressRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	resp, err := h.service.Update(ctx, id, custID, &req)
	if err != nil {
		if errors.Is(err, addressshared.ErrInvalidLocation) {
			return appErrors.BadRequest(c, err.Error())
		}
		if errors.Is(err, ErrNotFound) {
			return appErrors.NotFound(c, "address not found")
		}
		return appErrors.BadRequest(c, "failed to update address")
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Delete(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	id, err := utils.ParseUintParam(c, "id")
	if err != nil || custID == 0 {
		return appErrors.BadRequest(c, "invalid id or token")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	if err := h.service.Delete(ctx, id, custID); err != nil {
		if errors.Is(err, ErrCannotDeletePrimary) {
			return appErrors.Conflict(c, "cannot delete primary address")
		}
		if errors.Is(err, ErrNotFound) {
			return appErrors.NotFound(c, "address not found")
		}
		return appErrors.InternalError(c, "failed to delete address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "address deleted"})
}

func (h *Handler) SetPrimary(c fiber.Ctx) error {
	custID := utils.GetUserID(c)
	id, err := utils.ParseUintParam(c, "id")
	if err != nil || custID == 0 {
		return appErrors.BadRequest(c, "invalid id or token")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	if err := h.service.SetPrimary(ctx, id, custID); err != nil {
		if errors.Is(err, ErrNotFound) {
			return appErrors.NotFound(c, "address not found")
		}
		return appErrors.InternalError(c, "failed to set primary address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "primary address updated"})
}
