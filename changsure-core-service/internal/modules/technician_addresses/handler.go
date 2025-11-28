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
	techID := c.Locals("tech_id").(uint)

	var req CreateTechAddressReq
	if err := c.Bind().Body(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	id, err := h.svc.AddAddress(c.Context(), techID, req)
	if err != nil {
		return err
	}

	return c.JSON(fiber.Map{
		"id": id,
	})
}

func (h *Handler) UpdateAddress(c fiber.Ctx) error {
	idParam := c.Params("id")
	id, _ := strconv.Atoi(idParam)

	var req UpdateTechAddressReq
	if err := c.Bind().Body(&req); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	err := h.svc.UpdateAddress(c.Context(), uint(id), req)
	if err != nil {
		return err
	}

	return c.JSON(fiber.Map{"updated": true})
}

func (h *Handler) DeleteAddress(c fiber.Ctx) error {
	idParam := c.Params("id")
	id, _ := strconv.Atoi(idParam)

	err := h.svc.DeleteAddress(c.Context(), uint(id))
	if err != nil {
		return err
	}

	return c.JSON(fiber.Map{"deleted": true})
}

func (h *Handler) ListAddresses(c fiber.Ctx) error {
	techID := c.Locals("tech_id").(uint)

	items, err := h.svc.ListAddresses(c.Context(), techID)
	if err != nil {
		return err
	}

	return c.JSON(items)
}
