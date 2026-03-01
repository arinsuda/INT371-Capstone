package notification

import (
	"errors"
	"strconv"

	"github.com/gofiber/fiber/v3"
)

type AuthUser struct {
	ID   uint
	Role RecipientRole
}

type GetAuthUserFn func(c fiber.Ctx) (AuthUser, bool)

type Handler struct {
	svc         Service
	getAuthUser GetAuthUserFn
}

func NewHandler(svc Service, getAuthUser GetAuthUserFn) *Handler {
	return &Handler{svc: svc, getAuthUser: getAuthUser}
}

func (h *Handler) auth(c fiber.Ctx) (AuthUser, error) {
	u, ok := h.getAuthUser(c)
	if !ok || u.ID == 0 || !u.Role.Valid() {
		return AuthUser{}, fiber.NewError(fiber.StatusUnauthorized, "unauthorized")
	}
	return u, nil
}

func parseID(c fiber.Ctx) (uint, error) {
	n, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil || n == 0 {
		return 0, fiber.NewError(fiber.StatusBadRequest, "invalid notification id")
	}
	return uint(n), nil
}

func mapError(err error) error {
	switch {
	case errors.Is(err, ErrNotFound):
		return fiber.NewError(fiber.StatusNotFound, "notification not found")
	case errors.Is(err, ErrForbidden):
		return fiber.NewError(fiber.StatusForbidden, "access denied")
	case errors.Is(err, ErrInvalidRecipient):
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	default:
		return fiber.NewError(fiber.StatusInternalServerError, "internal server error")
	}
}

func (h *Handler) List(c fiber.Ctx) error {
	u, err := h.auth(c)
	if err != nil {
		return err
	}

	var q ListQuery
	if err := c.Bind().Query(&q); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid query parameters")
	}

	result, err := h.svc.List(c.Context(), u.Role, u.ID, q)
	if err != nil {
		return mapError(err)
	}

	return c.JSON(fiber.Map{"success": true, "data": result})
}

func (h *Handler) Get(c fiber.Ctx) error {
	u, err := h.auth(c)
	if err != nil {
		return err
	}
	id, err := parseID(c)
	if err != nil {
		return err
	}

	n, err := h.svc.Get(c.Context(), u.Role, u.ID, id)
	if err != nil {
		return mapError(err)
	}

	return c.JSON(fiber.Map{"success": true, "data": toResponse(*n)})
}

func (h *Handler) Patch(c fiber.Ctx) error {
	u, err := h.auth(c)
	if err != nil {
		return err
	}
	id, err := parseID(c)
	if err != nil {
		return err
	}

	var req PatchRequest
	if err := c.Bind().Body(&req); err != nil || req.IsRead == nil {
		return fiber.NewError(fiber.StatusBadRequest, "is_read (bool) is required")
	}

	n, err := h.svc.Patch(c.Context(), u.Role, u.ID, id, req)
	if err != nil {
		return mapError(err)
	}

	return c.JSON(fiber.Map{"success": true, "data": toResponse(*n)})
}

func (h *Handler) PatchBulk(c fiber.Ctx) error {
	u, err := h.auth(c)
	if err != nil {
		return err
	}

	var req PatchBulkRequest
	if err := c.Bind().Body(&req); err != nil || req.IsRead == nil || len(req.IDs) == 0 {
		return fiber.NewError(fiber.StatusBadRequest, "ids (array) and is_read (bool) are required")
	}

	affected, err := h.svc.PatchBulk(c.Context(), u.Role, u.ID, req)
	if err != nil {
		return mapError(err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    BulkUpdateResponse{Updated: affected},
	})
}
