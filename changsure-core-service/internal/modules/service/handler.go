package service

import (
	"net/http"
	"strconv"
	"strings"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc ServiceSvc }

func NewHandler(s ServiceSvc) *Handler { return &Handler{svc: s} }

func (h *Handler) Create(c fiber.Ctx) error {
	var req CreateServiceRequest
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	id, err := h.svc.Create(c.Context(), req)
	if err != nil {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	return c.Status(http.StatusCreated).
		JSON(fiber.Map{"success": true, "data": fiber.Map{"id": id}})
}

func (h *Handler) Update(c fiber.Ctx) error {
	id, err := toUint(c.Params("id"))
	if err != nil || id == 0 {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": "invalid id"})
	}

	var req UpdateServiceRequest
	if err := c.Bind().Body(&req); err != nil {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	if err := h.svc.Update(c.Context(), uint(id), req); err != nil {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	return c.JSON(fiber.Map{"success": true})
}

func (h *Handler) GetByID(c fiber.Ctx) error {
	id, err := toUint(c.Params("id"))
	if err != nil || id == 0 {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": "invalid id"})
	}

	m, err := h.svc.Get(c.Context(), uint(id))
	if err != nil {
		return c.Status(http.StatusNotFound).
			JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    MapServiceToResponse(m),
	})
}

func (h *Handler) List(c fiber.Ctx) error {
	var q ListQuery

	q.Search = c.Query("search")

	if v := c.Query("category_id"); v != "" {
		if id, err := toUint(v); err == nil && id > 0 {
			tmp := uint(id)
			q.CategoryID = &tmp
		}
	}

	if v := c.Query("is_active"); v != "" {
		if b, err := strconv.ParseBool(v); err == nil {
			q.IsActive = &b
		}
	}

	q.Page = toInt(c.Query("page"), 1)

	q.PageSize = toInt(c.Query("page_size"), 20)

	q.SortBy = strings.ToLower(c.Query("sort_by"))
	q.SortOrder = strings.ToLower(c.Query("sort_order"))

	items, total, err := h.svc.List(c.Context(), q)
	if err != nil {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	list := make([]ServiceResponse, 0, len(items))
	for _, it := range items {
		list = append(list, MapServiceToResponse(&it))
	}

	return c.JSON(fiber.Map{
		"success":   true,
		"total":     total,
		"page":      q.Page,
		"page_size": q.PageSize,
		"data":      list,
	})
}

func (h *Handler) Delete(c fiber.Ctx) error {
	id, err := toUint(c.Params("id"))
	if err != nil || id == 0 {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": "invalid id"})
	}

	if err := h.svc.Delete(c.Context(), uint(id)); err != nil {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": err.Error()})
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
