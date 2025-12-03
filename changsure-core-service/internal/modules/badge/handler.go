package badge

import (
	"context"
	"time"

	appErr "changsure-core-service/internal/errors"
	"changsure-core-service/internal/validation"
	utils "changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct{ svc Service }

func NewHandler(svc Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) GetBadge(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErr.BadRequest(c, "Invalid badge ID")
	}

	includeDeleted := utils.QueryBool(c, "include_deleted", false)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	badge, err := h.svc.FindBadge(ctx, id, includeDeleted)
	if err != nil {
		switch err {
		case ErrNotFound:
			return appErr.NotFound(c, "Badge not found")
		default:
			return appErr.InternalError(c, "Failed to fetch badge", err)
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    toResponse(badge),
	})
}

func (h *Handler) CreateBadge(c fiber.Ctx) error {
	var dto CreateBadgeDTO

	if err := c.Bind().Body(&dto); err != nil {
		return appErr.BadRequest(c, "Invalid request body")
	}
	if errs, err := validation.ValidateStruct(dto); err != nil {
		return appErr.ValidationError(c, errs)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	badge, err := h.svc.CreateBadge(ctx, dto)
	if err != nil {
		return appErr.InternalError(c, "Failed to create badge", err)
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    toResponse(badge),
	})
}

func (h *Handler) UpdateBadge(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErr.BadRequest(c, "Invalid badge ID")
	}

	var dto UpdateBadgeDTO
	if err := c.Bind().Body(&dto); err != nil {
		return appErr.BadRequest(c, "Invalid request body")
	}
	if errs, err := validation.ValidateStruct(dto); err != nil {
		return appErr.ValidationError(c, errs)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	badge, err := h.svc.UpdateBadge(ctx, id, dto)
	if err != nil {
		switch err {
		case ErrNotFound:
			return appErr.NotFound(c, "Badge not found")
		default:
			return appErr.InternalError(c, "Failed to update badge", err)
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    toResponse(badge),
	})
}

func (h *Handler) DeleteBadge(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErr.BadRequest(c, "Invalid badge ID")
	}

	hard := utils.QueryBool(c, "hard", false)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Hard delete
	if hard {
		if err := h.svc.HardDeleteBadge(ctx, id); err != nil {
			if err == ErrNotFound {
				return appErr.NotFound(c, "Badge not found")
			}
			return appErr.InternalError(c, "Failed to permanently delete badge", err)
		}

		return c.JSON(fiber.Map{
			"success": true,
			"message": "Badge permanently deleted",
		})
	}

	// Soft delete
	if err := h.svc.SoftDeleteBadge(ctx, id); err != nil {
		if err == ErrNotFound {
			return appErr.NotFound(c, "Badge not found")
		}
		return appErr.InternalError(c, "Failed to delete badge", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Badge deleted",
	})
}

func (h *Handler) RestoreBadge(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErr.BadRequest(c, "Invalid badge ID")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := h.svc.RestoreBadge(ctx, id); err != nil {
		if err == ErrNotFound {
			return appErr.NotFound(c, "Badge not found")
		}
		return appErr.InternalError(c, "Failed to restore badge", err)
	}

	return c.SendStatus(fiber.StatusOK)
}

func (h *Handler) ListBadges(c fiber.Ctx) error {
	var q ListBadgesQuery

	if err := c.Bind().Query(&q); err != nil {
		return appErr.BadRequest(c, "Invalid query parameters")
	}

	page, perPage := normalizePage(q.Page, q.PerPage)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	items, total, err := h.svc.ListBadges(ctx, q)
	if err != nil {
		return appErr.InternalError(c, "Failed to list badges", err)
	}

	return c.JSON(NewPaginated(toResponses(items), total, page, perPage))
}
