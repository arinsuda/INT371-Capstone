package customeraddress

import (
	"errors"

	"github.com/gofiber/fiber/v3"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
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
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var req CreateCustomerAddressRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	resp, err := h.service.Create(ctx, customerID, &req)
	if err != nil {
		return h.mapServiceError(c, "create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) List(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), customerID)

	list, err := h.service.List(ctx, customerID)
	if err != nil {
		return h.mapServiceError(c, "list addresses", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": list})
}

func (h *Handler) Get(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	addressID, err := utils.ParseUintParam(c, "addressID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid address id")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), customerID)

	resp, err := h.service.Get(ctx, addressID, customerID)
	if err != nil {
		return h.mapServiceError(c, "get address", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Update(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	addressID, err := utils.ParseUintParam(c, "addressID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid address id")
	}

	var req UpdateCustomerAddressRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	resp, err := h.service.Update(ctx, addressID, customerID, &req)
	if err != nil {
		return h.mapServiceError(c, "update address", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Delete(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	addressID, err := utils.ParseUintParam(c, "addressID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid address id")
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	if err := h.service.Delete(ctx, addressID, customerID); err != nil {
		return h.mapServiceError(c, "delete address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "address deleted"})
}

func (h *Handler) SetPrimary(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)
	}

	addressID, err := utils.ParseUintParam(c, "addressID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid address id")
	}

	var req UpdatePrimaryRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	if err := h.service.SetPrimary(ctx, addressID, customerID); err != nil {
		return h.mapServiceError(c, "set primary address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "primary address updated"})
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
	switch {
	case errors.Is(err, addressshared.ErrInvalidLocation):
		return appErrors.BadRequest(c, err.Error())
	case errors.Is(err, ErrNotFound):
		return appErrors.NotFound(c, "address not found")
	default:
		return appErrors.InternalError(c, "failed to "+action, err)
	}
}
