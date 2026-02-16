package technicianaddress

import (
	"errors"

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

func (h *Handler) mustTechID(c fiber.Ctx) (uint, error) {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return 0, customErr.Unauthorized(c, "invalid token")
	}
	return techID, nil
}

func (h *Handler) mustUintParam(c fiber.Ctx, name string) (uint, error) {
	id, err := utils.ParseUintParam(c, name)
	if err != nil || id == 0 {
		return 0, customErr.BadRequest(c, "invalid "+name)
	}
	return id, nil
}

func (h *Handler) bindAndValidate(c fiber.Ctx, dst any) error {
	if err := c.Bind().Body(dst); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(dst); err != nil {
		return customErr.ValidationError(c, details)
	}
	return nil
}

func (h *Handler) mapServiceError(c fiber.Ctx, action string, err error) error {
	if err == nil {
		return nil
	}

	if errors.Is(err, addressshared.ErrInvalidLocation) {
		return customErr.BadRequest(c, err.Error())
	}
	if errors.Is(err, ErrAddressNotFound) {
		return customErr.NotFound(c, "address not found")
	}

	return customErr.InternalError(c, "failed to "+action, err)
}

func (h *Handler) Create(c fiber.Ctx) error {
	techID, err := h.mustTechID(c)
	if err != nil {
		return err
	}

	var req CreateTechnicianAddressRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	resp, err := h.service.Create(ctx, techID, &req)
	if err != nil {
		return h.mapServiceError(c, "create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) List(c fiber.Ctx) error {
	techID, err := h.mustTechID(c)
	if err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	list, err := h.service.List(ctx, techID)
	if err != nil {
		return h.mapServiceError(c, "fetch addresses", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": list})
}

func (h *Handler) Get(c fiber.Ctx) error {
	techID, err := h.mustTechID(c)
	if err != nil {
		return err
	}

	id, err := h.mustUintParam(c, "id")
	if err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	resp, err := h.service.Get(ctx, id, techID)
	if err != nil {
		return h.mapServiceError(c, "get address", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Update(c fiber.Ctx) error {
	techID, err := h.mustTechID(c)
	if err != nil {
		return err
	}

	id, err := h.mustUintParam(c, "id")
	if err != nil {
		return err
	}

	var req UpdateTechnicianAddressRequest
	if err := h.bindAndValidate(c, &req); err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	resp, err := h.service.Update(ctx, id, techID, &req)
	if err != nil {

		if errors.Is(err, addressshared.ErrInvalidLocation) {
			return customErr.BadRequest(c, err.Error())
		}
		if errors.Is(err, ErrAddressNotFound) {
			return customErr.NotFound(c, "address not found")
		}
		return customErr.BadRequest(c, "failed to update address")
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Delete(c fiber.Ctx) error {
	techID, err := h.mustTechID(c)
	if err != nil {
		return err
	}

	id, err := h.mustUintParam(c, "id")
	if err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	if err := h.service.Delete(ctx, id, techID); err != nil {
		return h.mapServiceError(c, "delete address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "address deleted"})
}

func (h *Handler) SetPrimary(c fiber.Ctx) error {
	techID, err := h.mustTechID(c)
	if err != nil {
		return err
	}

	id, err := h.mustUintParam(c, "id")
	if err != nil {
		return err
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	if err := h.service.SetPrimary(ctx, id, techID); err != nil {
		return h.mapServiceError(c, "set primary address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "primary address updated"})
}

func (h *Handler) ListPublicAddresses(c fiber.Ctx) error {
	techID, err := h.mustUintParam(c, "id")
	if err != nil {
		return customErr.BadRequest(c, "invalid technician id")
	}

	list, err := h.service.ListPublic(c.Context(), techID)
	if err != nil {
		return customErr.InternalError(c, "failed to fetch addresses", err)
	}

	publicData := make([]fiber.Map, 0, len(list))
	for _, a := range list {
		publicData = append(publicData, fiber.Map{
			"id":                a.ID,
			"province_name":     a.ProvinceName,
			"district_name":     a.DistrictName,
			"sub_district_name": a.SubDistrictName,
			"postal_code":       a.PostalCode,
			"latitude":          a.Latitude,
			"longitude":         a.Longitude,
			"is_primary":        a.IsPrimary,
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    publicData,
	})
}

func (h *Handler) SearchNearby(c fiber.Ctx) error {
	var req addressshared.NearbyQuery
	if err := c.Bind().Body(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(req); err != nil {
		return customErr.ValidationError(c, details)
	}

	results, err := h.service.FindNearby(c.Context(), req)
	if err != nil {
		return customErr.InternalError(c, "failed to search nearby technicians", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": results})
}
