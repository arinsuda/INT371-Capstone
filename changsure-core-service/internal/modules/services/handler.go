package services

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

	return c.JSON(fiber.Map{"success": true, "data": m})
}

func (h *Handler) List(c fiber.Ctx) error {
	var q ListQuery

	q.Search = c.Query("search")

	// category_id
	if v := c.Query("category_id"); v != "" {
		if id, err := toUint(v); err == nil && id > 0 {
			tmp := uint(id)
			q.CategoryID = &tmp
		}
	}

	// is_active
	if v := c.Query("is_active"); v != "" {
		if b, err := strconv.ParseBool(v); err == nil {
			q.IsActive = &b
		}
	}

	// page
	q.Page = toInt(c.Query("page"), 1)

	// page_size
	q.PageSize = toInt(c.Query("page_size"), 20)

	// sort_by & sort_order
	q.SortBy = strings.ToLower(c.Query("sort_by"))
	q.SortOrder = strings.ToLower(c.Query("sort_order"))

	items, total, err := h.svc.List(c.Context(), q)
	if err != nil {
		return c.Status(http.StatusBadRequest).
			JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	return c.JSON(fiber.Map{
		"success":   true,
		"total":     total,
		"page":      q.Page,
		"page_size": q.PageSize,
		"data":      items,
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
