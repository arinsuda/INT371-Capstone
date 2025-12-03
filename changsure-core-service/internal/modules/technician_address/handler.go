package technicianaddress

import (
	"errors"
	"strconv"

	customErr "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	addressshared "changsure-core-service/internal/modules/address_shared"
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
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return customErr.BadRequest(c, "invalid technician token")
	}

	var req CreateTechnicianAddressRequest
	if err := c.Bind().JSON(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return customErr.ValidationError(c, details)
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.Create(ctx, techID, &req)
	if err != nil {
		return customErr.InternalError(c, "failed to create address", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) ListAddresses(c fiber.Ctx) error {
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return customErr.BadRequest(c, "invalid technician token")
	}

	ctx := middleware.GetContext(c)
	list, err := h.service.List(ctx, techID)
	if err != nil {
		return customErr.InternalError(c, "failed to fetch addresses", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponseList(list),
	})
}

func (h *Handler) GetAddress(c fiber.Ctx) error {
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return customErr.BadRequest(c, "invalid technician token")
	}

	addrRaw := c.Params("id")
	addrID, err := strconv.ParseUint(addrRaw, 10, 32)
	if err != nil || addrID == 0 {
		return customErr.BadRequest(c, "invalid address id")
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.Get(ctx, uint(addrID), techID)
	if err != nil {
		if errors.Is(err, addressshared.ErrAddressNotFound) {
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
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return customErr.BadRequest(c, "invalid technician token")
	}

	addrRaw := c.Params("id")
	addrID, err := strconv.ParseUint(addrRaw, 10, 32)
	if err != nil || addrID == 0 {
		return customErr.BadRequest(c, "invalid address id")
	}

	var req UpdateTechnicianAddressRequest
	if err := c.Bind().JSON(&req); err != nil {
		return customErr.BadRequest(c, "invalid request body")
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return customErr.ValidationError(c, details)
	}

	ctx := middleware.GetContext(c)
	addr, err := h.service.Update(ctx, uint(addrID), techID, &req)
	if err != nil {
		if errors.Is(err, addressshared.ErrAddressNotFound) {
			return customErr.NotFound(c, "address not found")
		}
		return customErr.InternalError(c, "failed to update address", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   ToResponse(addr),
	})
}

func (h *Handler) DeleteAddress(c fiber.Ctx) error {
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return customErr.BadRequest(c, "invalid technician token")
	}

	addrRaw := c.Params("id")
	addrID, err := strconv.ParseUint(addrRaw, 10, 32)
	if err != nil || addrID == 0 {
		return customErr.BadRequest(c, "invalid address id")
	}

	ctx := middleware.GetContext(c)
	if err := h.service.Delete(ctx, uint(addrID), techID); err != nil {
		if errors.Is(err, addressshared.ErrAddressNotFound) {
			return customErr.NotFound(c, "address not found")
		}
		return customErr.InternalError(c, "failed to delete address", err)
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "address deleted",
	})
}

func (h *Handler) SetPrimaryAddress(c fiber.Ctx) error {
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return customErr.BadRequest(c, "invalid technician token")
	}

	addrRaw := c.Params("id")
	addrID, err := strconv.ParseUint(addrRaw, 10, 32)
	if err != nil || addrID == 0 {
		return customErr.BadRequest(c, "invalid address id")
	}

	ctx := middleware.GetContext(c)
	if err := h.service.SetPrimary(ctx, uint(addrID), techID); err != nil {
		if errors.Is(err, addressshared.ErrAddressNotFound) {
			return customErr.NotFound(c, "address not found")
		}
		return customErr.InternalError(c, "failed to set primary address", err)
	}

	return c.JSON(fiber.Map{
		"status":  "success",
		"message": "primary address updated",
	})
}

func (h *Handler) ListPublicAddresses(c fiber.Ctx) error {
	raw := c.Params("id")
	techID, err := strconv.ParseUint(raw, 10, 32)
	if err != nil || techID == 0 {
		return customErr.BadRequest(c, "invalid technician id")
	}

	ctx := middleware.GetContext(c)
	list, err := h.service.List(ctx, uint(techID))
	if err != nil {
		return customErr.InternalError(c, "failed to fetch addresses", err)
	}

	public := make([]fiber.Map, 0, len(list))
	for _, a := range list {
		public = append(public, fiber.Map{
			"province":     a.Province,
			"district":     a.District,
			"sub_district": a.SubDistrict,
		})
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   public,
	})
}

func (h *Handler) SearchNearby(c fiber.Ctx) error {
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

	ctx := middleware.GetContext(c)
	results, err := h.service.FindNearby(ctx, req)
	if err != nil {
		return customErr.InternalError(c, "failed to search nearby technicians", err)
	}

	return c.JSON(fiber.Map{
		"status": "success",
		"data":   results,
	})
}
