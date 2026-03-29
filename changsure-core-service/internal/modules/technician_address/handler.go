package technicianaddress

import (
	"errors"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
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
	if errors.Is(err, addressshared.ErrInvalidLocation) {
		return appErrors.BadRequest(c, err.Error())
	}
	if errors.Is(err, ErrAddressNotFound) {
		return appErrors.NotFound(c, "address not found")
	}
	return appErrors.InternalError(c, "failed to "+action, err)
}

func (h *Handler) Create(c fiber.Ctx) error {
	techID, err := h.mustUintParam(c, "technicianID")
	if err != nil {
		return err
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var req CreateTechnicianAddressRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	resp, err := h.service.Create(ctx, techID, &req)
	if err != nil {
		return h.mapServiceError(c, "create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) List(c fiber.Ctx) error {
	techID, err := h.mustUintParam(c, "technicianID")
	if err != nil {
		return err
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	list, err := h.service.List(c.Context(), techID)
	if err != nil {
		return h.mapServiceError(c, "fetch addresses", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": list})
}

func (h *Handler) Get(c fiber.Ctx) error {
	techID, err := h.mustUintParam(c, "technicianID")
	if err != nil {
		return err
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	addressID, err := h.mustUintParam(c, "addressID")
	if err != nil {
		return err
	}

	resp, err := h.service.Get(c.Context(), addressID, techID)
	if err != nil {
		return h.mapServiceError(c, "get address", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Update(c fiber.Ctx) error {
	techID, err := h.mustUintParam(c, "technicianID")
	if err != nil {
		return err
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	addressID, err := h.mustUintParam(c, "addressID")
	if err != nil {
		return err
	}

	var req UpdateTechnicianAddressRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	resp, err := h.service.Update(ctx, addressID, techID, &req)
	if err != nil {
		return h.mapServiceError(c, "update address", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Delete(c fiber.Ctx) error {
	techID, err := h.mustUintParam(c, "technicianID")
	if err != nil {
		return err
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	addressID, err := h.mustUintParam(c, "addressID")
	if err != nil {
		return err
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	if err := h.service.Delete(ctx, addressID, techID); err != nil {
		return h.mapServiceError(c, "delete address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "address deleted"})
}

func (h *Handler) SetPrimary(c fiber.Ctx) error {
	techID, err := h.mustUintParam(c, "technicianID")
	if err != nil {
		return err
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	addressID, err := h.mustUintParam(c, "addressID")
	if err != nil {
		return err
	}

	var req UpdatePrimaryRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	if err := h.service.SetPrimary(ctx, addressID, techID, req.IsPrimary); err != nil {
		return h.mapServiceError(c, "update primary", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "primary address updated"})
}

func (h *Handler) SearchNearby(c fiber.Ctx) error {
	var req addressshared.NearbyQuery
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	results, err := h.service.FindNearby(c.Context(), req)
	if err != nil {
		return appErrors.InternalError(c, "failed to search nearby technicians", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": results})
}
