package badge

import (
	"context"
	"time"

	utils "changsure-core-service/pkg/utils"
	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc Service }

func NewHandler(svc Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) Get(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid id")
	}

	includeDeleted := utils.QueryBool(c, "include_deleted", false)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	b, err := h.svc.Get(ctx, id, includeDeleted)
	if err != nil {
		if err == ErrNotFound {
			return fiber.NewError(fiber.StatusNotFound, "badge not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(toResponse(b))
}

func (h *Handler) Create(c fiber.Ctx) error {
	var dto CreateBadgeDTO
	if err := c.Bind().Body(&dto); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}
	if err := ValidateStruct(dto); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	b, err := h.svc.Create(ctx, dto)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusCreated).JSON(toResponse(b))
}

func (h *Handler) Update(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid id")
	}

	var dto UpdateBadgeDTO
	if err := c.Bind().Body(&dto); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid body")
	}
	if err := ValidateStruct(dto); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, err.Error())
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	b, err := h.svc.Update(ctx, id, dto)
	if err != nil {
		if err == ErrNotFound {
			return fiber.NewError(fiber.StatusNotFound, "badge not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.JSON(toResponse(b))
}

func (h *Handler) Delete(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid id")
	}

	hard := utils.QueryBool(c, "hard", false)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if hard {
		if err := h.svc.HardDelete(ctx, id); err != nil {
			if err == ErrNotFound {
				return fiber.NewError(fiber.StatusNotFound, "badge not found")
			}
			return fiber.NewError(fiber.StatusInternalServerError, err.Error())
		}
		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"success": true,
			"message": "badge permanently deleted",
		})
	}

	if err := h.svc.Delete(ctx, id); err != nil {
		if err == ErrNotFound {
			return fiber.NewError(fiber.StatusNotFound, "badge not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"success": true,
		"message": "badge deleted",
	})
}

func (h *Handler) Restore(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := h.svc.Restore(ctx, id); err != nil {
		if err == ErrNotFound {
			return fiber.NewError(fiber.StatusNotFound, "badge not found")
		}
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}
	return c.SendStatus(fiber.StatusOK)
}

func (h *Handler) List(c fiber.Ctx) error {
	var q ListBadgesQuery
	if err := c.Bind().Query(&q); err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid query")
	}
	page, perPage := normalizePage(q.Page, q.PerPage)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	items, total, err := h.svc.List(ctx, q)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	return c.JSON(NewPaginated(toResponses(items), total, page, perPage))
}
