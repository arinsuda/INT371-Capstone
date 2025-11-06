package services

import (
	"net/http"
	"strconv"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc ServiceSvc }

func NewHandler(s ServiceSvc) *Handler { return &Handler{svc: s} }

func (h *Handler) Create(c fiber.Ctx) error {
	var req CreateServiceRequest
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	id, err := h.svc.Create(c.Context(), req)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	return c.Status(http.StatusCreated).JSON(fiber.Map{"success": true, "data": fiber.Map{"id": id}})
}

func (h *Handler) Update(c fiber.Ctx) error {
	id, err := toUint(c.Params("id"))
	if err != nil || id == 0 {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": "invalid id"})
	}
	var req UpdateServiceRequest
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	if err := h.svc.Update(c.Context(), uint(id), req); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	return c.JSON(fiber.Map{"success": true})
}

func (h *Handler) GetByID(c fiber.Ctx) error {
	id, err := toUint(c.Params("id"))
	if err != nil || id == 0 {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": "invalid id"})
	}
	m, err := h.svc.Get(c.Context(), uint(id))
	if err != nil {
		return c.Status(http.StatusNotFound).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	return c.JSON(fiber.Map{"success": true, "data": m})
}

func (h *Handler) List(c fiber.Ctx) error {
	q := ListQuery{}
	if v := c.Query("category_id"); v != "" {
		if id64, err := toUint(v); err == nil {
			u := uint(id64)
			q.CategoryID = &u
		}
	}
	if v := c.Query("active"); v != "" {
		if v == "1" || v == "true" {
			t := true
			q.Active = &t
		} else if v == "0" || v == "false" {
			f := false
			q.Active = &f
		}
	}
	q.Search = c.Query("q")
	q.Page = toInt(c.Query("page"), 1)
	q.PageSize = toInt(c.Query("page_size"), 20)

	items, total, err := h.svc.List(c.Context(), q)
	if err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	return c.JSON(fiber.Map{"success": true, "data": items, "total": total, "page": q.Page, "page_size": q.PageSize})
}

func (h *Handler) Delete(c fiber.Ctx) error {
	id, err := toUint(c.Params("id"))
	if err != nil || id == 0 {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": "invalid id"})
	}
	if err := h.svc.Delete(c.Context(), uint(id)); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	return c.JSON(fiber.Map{"success": true})
}

func toUint(s string) (uint64, error) { return strconv.ParseUint(s, 10, 64) }
func toInt(s string, def int) int {
	if s == "" {
		return def
	}
	i, err := strconv.Atoi(s)
	if err != nil {
		return def
	}
	return i
}
