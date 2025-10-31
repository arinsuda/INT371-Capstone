package customeraddresses

import (
	"strconv"

	"changsure-core-service/internal/middleware"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler { return &Handler{service: s} }

func (h *Handler) CreateAddress(c fiber.Ctx) error {
	custID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil { return badRequest(c, "Invalid customer ID") }

	var req CreateCustomerAddressRequest
	if err := c.Bind().JSON(&req); err != nil { return badRequest(c, "Invalid request body") }
	if err := req.Validate(); err != nil { return badRequest(c, err.Error()) }

	ctx := middleware.GetContext(c)
	addr, err := h.service.CreateAddress(ctx, uint(custID), &req)
	if err != nil { return internalErr(c, "Failed to create address", err) }

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"status":"success","data":ToResponse(addr),
	})
}

func (h *Handler) ListAddresses(c fiber.Ctx) error {
	custID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil { return badRequest(c, "Invalid customer ID") }

	ctx := middleware.GetContext(c)
	list, err := h.service.ListAddresses(ctx, uint(custID))
	if err != nil { return internalErr(c, "Failed to list addresses", err) }

	return c.JSON(fiber.Map{"status":"success","data":ToResponseList(list)})
}

func (h *Handler) GetAddress(c fiber.Ctx) error {
	addrID, err := strconv.ParseUint(c.Params("addrId"), 10, 32)
	if err != nil { return badRequest(c, "Invalid address ID") }

	ctx := middleware.GetContext(c)
	addr, err := h.service.GetAddress(ctx, uint(addrID))
	if err != nil { return internalErr(c, "Failed to get address", err) }
	if addr == nil { return notFound(c, "Address not found") }

	return c.JSON(fiber.Map{"status":"success","data":ToResponse(addr)})
}

func (h *Handler) UpdateAddress(c fiber.Ctx) error {
	addrID, err := strconv.ParseUint(c.Params("addrId"), 10, 32)
	if err != nil { return badRequest(c, "Invalid address ID") }

	var req UpdateCustomerAddressRequest
	if err := c.Bind().JSON(&req); err != nil { return badRequest(c, "Invalid request body") }
	if err := req.Validate(); err != nil { return badRequest(c, err.Error()) }

	ctx := middleware.GetContext(c)
	addr, err := h.service.UpdateAddress(ctx, uint(addrID), &req)
	if err != nil { return internalErr(c, "Failed to update address", err) }

	return c.JSON(fiber.Map{"status":"success","data":ToResponse(addr)})
}

func (h *Handler) DeleteAddress(c fiber.Ctx) error {
	addrID, err := strconv.ParseUint(c.Params("addrId"), 10, 32)
	if err != nil { return badRequest(c, "Invalid address ID") }

	ctx := middleware.GetContext(c)
	if err := h.service.DeleteAddress(ctx, uint(addrID)); err != nil {
		return internalErr(c, "Failed to delete address", err)
	}
	return c.JSON(fiber.Map{"status":"success","message":"Address deleted successfully"})
}

type SearchNearbyAddressRequest struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	RadiusKm  float64 `json:"radius_km"`
}

func (h *Handler) SearchNearby(c fiber.Ctx) error {
	var req SearchNearbyAddressRequest
	if err := c.Bind().JSON(&req); err != nil { return badRequest(c, "Invalid request body") }

	ctx := middleware.GetContext(c)
	list, err := h.service.FindNearby(ctx, req.Latitude, req.Longitude, req.RadiusKm, 50)
	if err != nil { return internalErr(c, "Failed to search nearby addresses", err) }

	return c.JSON(fiber.Map{
		"status":"success",
		"data": fiber.Map{
			"addresses": ToResponseList(list),
			"count":     len(list),
		},
	})
}

func badRequest(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"status":"error","message":msg})
}
func notFound(c fiber.Ctx, msg string) error {
	return c.Status(fiber.StatusNotFound).JSON(fiber.Map{"status":"error","message":msg})
}
func internalErr(c fiber.Ctx, msg string, _ error) error {
	return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"status":"error","message":msg})
}