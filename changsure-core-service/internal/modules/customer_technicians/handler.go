package customer_technicians

import (
	"github.com/gofiber/fiber/v3"
	"strconv"
)

type Handler struct{ svc Service }

func NewHandler(s Service) *Handler { return &Handler{svc: s} }

func (h *Handler) List(c fiber.Ctx) error {
	q := TechnicianListQuery{}

	if v := c.Query("service_id"); v != "" {
		id, _ := strconv.Atoi(v)
		tmp := uint(id)
		q.ServiceID = &tmp
	}

	if v := c.Query("province_id"); v != "" {
		id, _ := strconv.Atoi(v)
		tmp := uint(id)
		q.ProvinceID = &tmp
	}

	items, err := h.svc.List(c.Context(), q)
	if err != nil {
		return fiber.NewError(500, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "data": items})
}

func (h *Handler) GetByID(c fiber.Ctx) error {
	id, err := strconv.Atoi(c.Params("id"))
	if err != nil {
		return fiber.NewError(400, "invalid id")
	}

	res, err := h.svc.GetByID(c.Context(), uint(id))
	if err != nil {
		return fiber.NewError(404, "technician not found")
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) AutoSelect(c fiber.Ctx) error {
	var req AutoSelectRequest
	if err := c.Bind().Body(&req); err != nil {
		return fiber.NewError(400, "invalid request")
	}

	res, err := h.svc.AutoSelect(c.Context(), req)
	if err != nil {
		return fiber.NewError(500, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}
