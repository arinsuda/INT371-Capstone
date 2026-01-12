package technicianaddress

import (
	"errors"
	"strconv"

	customErr "changsure-core-service/internal/errors"
	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/internal/validation"

	"github.com/gofiber/fiber/v3"

	"changsure-core-service/pkg/utils"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) CreateAddress(c fiber.Ctx) error {
	techID := utils.GetUserID(c) // ใช้ helper ถ้ามี
	if techID == 0 {
		return customErr.Unauthorized(c, "invalid token")
	}

	var req CreateTechnicianAddressRequest
	if err := c.Bind().Body(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return customErr.ValidationError(c, details)
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	resp, err := h.service.Create(ctx, techID, &req)
	if err != nil {
		if errors.Is(err, addressshared.ErrInvalidLocation) {
			return customErr.BadRequest(c, err.Error())
		}
		return customErr.InternalError(c, "failed to create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) ListAddresses(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return customErr.Unauthorized(c, "invalid token")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	list, err := h.service.List(ctx, techID)
	if err != nil {
		return customErr.InternalError(c, "failed to fetch addresses", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": list})
}

func (h *Handler) GetAddress(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil || techID == 0 {
		return customErr.BadRequest(c, "invalid id or token")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	resp, err := h.service.Get(ctx, uint(id), techID)
	if err != nil {
		if errors.Is(err, ErrAddressNotFound) {
			return customErr.NotFound(c, "address not found")
		}
		return customErr.InternalError(c, "failed to get address", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) UpdateAddress(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil || techID == 0 {
		return customErr.BadRequest(c, "invalid id or token")
	}

	var req UpdateTechnicianAddressRequest
	if err := c.Bind().Body(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	resp, err := h.service.Update(ctx, uint(id), techID, &req)
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

func (h *Handler) DeleteAddress(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil || techID == 0 {
		return customErr.BadRequest(c, "invalid id or token")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	if err := h.service.Delete(ctx, uint(id), techID); err != nil {
		if errors.Is(err, ErrAddressNotFound) {
			return customErr.NotFound(c, "address not found")
		}
		if errors.Is(err, ErrCannotDeletePrimary) {
			return customErr.Conflict(c, "cannot delete primary address")
		}
		return customErr.InternalError(c, "failed to delete address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "address deleted"})
}

func (h *Handler) SetPrimaryAddress(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil || techID == 0 {
		return customErr.BadRequest(c, "invalid id or token")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), techID)

	if err := h.service.SetPrimary(ctx, uint(id), techID); err != nil {
		if errors.Is(err, ErrAddressNotFound) {
			return customErr.NotFound(c, "address not found")
		}
		return customErr.InternalError(c, "failed to set primary address", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "primary address updated"})
}

func (h *Handler) ListPublicAddresses(c fiber.Ctx) error {
	id, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return customErr.BadRequest(c, "invalid technician id")
	}

	list, err := h.service.ListPublic(c.Context(), uint(id))
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

	results, err := h.service.FindNearby(c.Context(), req)
	if err != nil {
		return customErr.InternalError(c, "failed to search nearby technicians", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": results})
}
