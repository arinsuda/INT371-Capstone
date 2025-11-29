package technician_addresses

import (
	"strconv"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc Service
}

func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) AddAddress(c fiber.Ctx) error {
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return fiber.NewError(fiber.StatusUnauthorized, "invalid technician token")
	}

	var req CreateTechAddressReq
	if err := c.Bind().Body(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	id, err := h.svc.AddAddress(c.Context(), techID, req)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"id":      id,
		"message": "created",
	})
}

func (h *Handler) ListMyAddresses(c fiber.Ctx) error {
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return fiber.NewError(fiber.StatusUnauthorized, "invalid technician token")
	}

	items, err := h.svc.ListAddresses(c.Context(), techID)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    items,
	})
}

func (h *Handler) UpdateMyAddress(c fiber.Ctx) error {
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return fiber.NewError(fiber.StatusUnauthorized, "invalid technician token")
	}

	id, err := strconv.Atoi(c.Params("id"))
	if err != nil || id <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid address id")
	}

	addr, err := h.svc.GetAddress(c.Context(), uint(id))
	if err != nil {
		return fiber.NewError(fiber.StatusNotFound, "address not found")
	}

	if addr.TechnicianID != techID {
		return fiber.NewError(fiber.StatusForbidden, "you do not own this address")
	}

	var req UpdateTechAddressReq
	if err := c.Bind().Body(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	if err := h.svc.UpdateAddress(c.Context(), uint(id), req); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "updated": true})
}

func (h *Handler) DeleteMyAddress(c fiber.Ctx) error {
	techID := c.Locals("userID").(uint)

	id, err := strconv.Atoi(c.Params("id"))
	if err != nil || id <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid address id")
	}

	addr, err := h.svc.GetAddress(c.Context(), uint(id))
	if err != nil {
		return fiber.NewError(fiber.StatusNotFound, "address not found")
	}

	if addr.TechnicianID != techID {
		return fiber.NewError(fiber.StatusForbidden, "you do not own this address")
	}

	if err := h.svc.DeleteAddress(c.Context(), uint(id)); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "deleted": true})
}

func (h *Handler) PublicAddresses(c fiber.Ctx) error {
	techID, err := strconv.Atoi(c.Params("id"))
	if err != nil || techID <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid technician id")
	}

	items, err := h.svc.ListAddresses(c.Context(), uint(techID))
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	public := make([]fiber.Map, 0, len(items))
	for _, it := range items {
		public = append(public, fiber.Map{
			"province":     it.Province,
			"district":     it.District,
			"sub_district": it.SubDistrict,
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    public,
	})
}

func (h *Handler) SetPrimaryAddress(c fiber.Ctx) error {
	techID, ok := c.Locals("userID").(uint)
	if !ok || techID == 0 {
		return fiber.NewError(fiber.StatusUnauthorized, "invalid technician token")
	}

	addrID, err := strconv.Atoi(c.Params("id"))
	if err != nil || addrID <= 0 {
		return fiber.NewError(fiber.StatusBadRequest, "invalid address id")
	}

	addr, err := h.svc.GetAddress(c.Context(), uint(addrID))
	if err != nil {
		return fiber.NewError(fiber.StatusNotFound, "address not found")
	}

	if addr.TechnicianID != techID {
		return fiber.NewError(fiber.StatusForbidden, "you do not own this address")
	}

	if err := h.svc.SetPrimaryAddress(c.Context(), techID, uint(addrID)); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "primary address updated",
	})
}
