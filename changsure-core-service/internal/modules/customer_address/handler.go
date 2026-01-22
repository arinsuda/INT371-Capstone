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

// --- helpers (keep handlers small & consistent) ---

func (h *Handler) mustCustomerID(c fiber.Ctx) (uint, error) {
	custID := utils.GetUserID(c)
	if custID == 0 {
		return 0, appErrors.Unauthorized(c, "unauthorized")
	}
	return custID, nil
}

func (h *Handler) mustUintParam(c fiber.Ctx, name string) (uint, error) {
	id, err := utils.ParseUintParam(c, name)
	if err != nil || id == 0 {
		return 0, appErrors.BadRequest(c, "invalid "+name)
	}
	return id, nil
}

func (h *Handler) bindAndValidate(c fiber.Ctx, dst any) error {
	if err := c.Bind().Body(dst); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(dst); err != nil {
		return appErrors.ValidationError(c, details)
	}
	return nil
}

func (h *Handler) mapServiceError(c fiber.Ctx, action string, err error) error {
	if err == nil {
		return nil
	}

	// Validation / domain errors
	if errors.Is(err, addressshared.ErrInvalidLocation) {
		return appErrors.BadRequest(c, err.Error())
	}
	if errors.Is(err, ErrNotFound) {
		return appErrors.NotFound(c, "address not found")
	}
	if errors.Is(err, ErrUnauthorized) {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	// Default
	return appErrors.InternalError(c, "failed to "+action, err)
}

// --- handlers ---

func (h *Handler) Create(c fiber.Ctx) error {
	custID, err := h.mustCustomerID(c)
	if err != nil {
		return err
	}

	var req CreateCustomerAddressRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	resp, err := h.service.Create(ctx, custID, &req)
	if err != nil {
		return h.mapServiceError(c, "create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) List(c fiber.Ctx) error {
	custID, err := h.mustCustomerID(c)
	if err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	list, err := h.service.List(ctx, custID)
	if err != nil {
		return h.mapServiceError(c, "list addresses", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": list})
}

func (h *Handler) Get(c fiber.Ctx) error {
	custID, err := h.mustCustomerID(c)
	if err != nil {
		return err
	}

	id, err := h.mustUintParam(c, "id")
	if err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	resp, err := h.service.Get(ctx, id, custID)
	if err != nil {
		return h.mapServiceError(c, "get address", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Update(c fiber.Ctx) error {
	custID, err := h.mustCustomerID(c)
	if err != nil {
		return err
	}

	id, err := h.mustUintParam(c, "id")
	if err != nil {
		return err
	}

	var req UpdateCustomerAddressRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
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
		if errors.Is(err, ErrUnauthorized) {
			return appErrors.Unauthorized(c, "unauthorized")
		}
		return appErrors.BadRequest(c, "failed to update address")
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Delete(c fiber.Ctx) error {
	custID, err := h.mustCustomerID(c)
	if err != nil {
		return err
	}

	id, err := h.mustUintParam(c, "id")
	if err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	if err := h.service.Delete(ctx, id, custID); err != nil {
		return h.mapServiceError(c, "delete address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "address deleted"})
}

func (h *Handler) SetPrimary(c fiber.Ctx) error {
	custID, err := h.mustCustomerID(c)
	if err != nil {
		return err
	}

	id, err := h.mustUintParam(c, "id")
	if err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), custID)

	if err := h.service.SetPrimary(ctx, id, custID); err != nil {
		return h.mapServiceError(c, "set primary address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "primary address updated"})
}
