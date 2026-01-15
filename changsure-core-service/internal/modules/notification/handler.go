package notification

import (
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

func (h *Handler) List(c fiber.Ctx) error {
	u, ok := h.getAuthUser(c)
	if !ok || u.ID == 0 || !u.Role.Valid() {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"message": "unauthorized"})
	}

	var q ListQuery
	_ = c.Bind().Query(&q)

	items, nextCursor, err := h.svc.List(c.Context(), u.Role, u.ID, q)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"message": err.Error()})
	}

	return c.JSON(fiber.Map{
		"items":       items,
		"next_cursor": nextCursor,
	})
}

func (h *Handler) UnreadCount(c fiber.Ctx) error {
	u, ok := h.getAuthUser(c)
	if !ok || u.ID == 0 || !u.Role.Valid() {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"message": "unauthorized"})
	}

	count, err := h.svc.UnreadCount(c.Context(), u.Role, u.ID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"message": err.Error()})
	}

	return c.JSON(fiber.Map{"unread_count": count})
}

func (h *Handler) MarkRead(c fiber.Ctx) error {
	u, ok := h.getAuthUser(c)
	if !ok || u.ID == 0 || !u.Role.Valid() {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"message": "unauthorized"})
	}

	var req MarkReadRequest
	if err := c.Bind().Body(&req); err != nil || len(req.IDs) == 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{"message": "invalid payload"})
	}

	affected, err := h.svc.MarkRead(c.Context(), u.Role, u.ID, req.IDs)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"message": err.Error()})
	}

	return c.JSON(fiber.Map{"updated": affected})
}

func (h *Handler) ReadAll(c fiber.Ctx) error {
	u, ok := h.getAuthUser(c)
	if !ok || u.ID == 0 || !u.Role.Valid() {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{"message": "unauthorized"})
	}

	affected, err := h.svc.ReadAll(c.Context(), u.Role, u.ID)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{"message": err.Error()})
	}

	return c.JSON(fiber.Map{"updated": affected})
}
