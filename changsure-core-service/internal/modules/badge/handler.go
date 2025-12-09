package badge

import (
	"bytes"
	"context"
	"fmt"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"changsure-core-service/pkg/imageutil"
	"github.com/google/uuid"

	appErr "changsure-core-service/internal/errors"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/storage"
	utils "changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc   Service
	store *storage.MinioStorage
}

func NewHandler(svc Service, store *storage.MinioStorage) *Handler {
	return &Handler{
		svc:   svc,
		store: store,
	}
}

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
		if err == ErrNotFound {
			return appErr.NotFound(c, "Badge not found")
		}
		return appErr.InternalError(c, "Failed to fetch badge", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    toResponse(badge, h.store),
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
		"data":    toResponse(badge, h.store),
	})
}

func (h *Handler) UpdateBadge(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErr.BadRequest(c, "invalid badge ID")
	}

	name := c.FormValue("name")
	description := c.FormValue("description")
	levelStr := c.FormValue("level")
	activeStr := c.FormValue("is_active")

	var dto UpdateBadgeDTO

	if name != "" {
		dto.Name = &name
	}
	if description != "" {
		dto.Description = &description
	}
	if levelStr != "" {
		u64, err := strconv.ParseUint(levelStr, 10, 64)
		if err != nil {
			return appErr.BadRequest(c, "level must be a valid number")
		}
		lvl := uint(u64)
		dto.Level = &lvl
	}

	if activeStr != "" {
		isActive := activeStr == "true" || activeStr == "1"
		dto.IsActive = &isActive
	}

	fileHeader, err := c.FormFile("file")
	if err != nil || fileHeader == nil {
		fileHeader, err = c.FormFile("icon_url")
	}
	if err == nil && fileHeader != nil {
		file, err := fileHeader.Open()
		if err != nil {
			return fiber.NewError(500, "cannot open file")
		}
		defer file.Close()

		var raw bytes.Buffer
		raw.ReadFrom(file)

		opt := imageutil.ResizeOptions{
			MaxWidth:    512,
			MaxFileSize: 500_000,
			Quality:     85,
		}
		imgBuf, err := imageutil.OptimizeImage(bytes.NewReader(raw.Bytes()), opt)
		if err != nil {
			return fiber.NewError(400, "invalid image")
		}

		ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
		if ext == "" {
			ext = ".png"
		}

		key := fmt.Sprintf(
			"badges/%d/%d_%s%s",
			id,
			time.Now().Unix(),
			uuid.NewString(),
			ext,
		)

		ctx, cancel := context.WithTimeout(c.Context(), 10*time.Second)
		defer cancel()

		_, err = h.store.Put(
			ctx,
			key,
			bytes.NewReader(imgBuf.Bytes()),
			int64(imgBuf.Len()),
			"image/png",
		)
		if err != nil {
			return fiber.NewError(500, "failed to upload image: "+err.Error())
		}

		dto.IconURL = &key
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	badge, err := h.svc.UpdateBadge(ctx, id, dto)
	if err != nil {
		if err == ErrNotFound {
			return appErr.NotFound(c, "badge not found")
		}
		return appErr.InternalError(c, "update failed", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    toResponse(badge, h.store),
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

	return c.JSON(NewPaginated(toResponses(items, h.store), total, page, perPage))
}

func (h *Handler) UploadIcon(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(400, "invalid id")
	}

	fileHeader, err := c.FormFile("file")
	if err != nil {
		return fiber.NewError(400, "file is required")
	}

	file, err := fileHeader.Open()
	if err != nil {
		return fiber.NewError(500, "cannot open file")
	}
	defer file.Close()

	var raw bytes.Buffer
	raw.ReadFrom(file)

	opt := imageutil.ResizeOptions{
		MaxWidth:    512,
		MaxFileSize: 500_000,
		Quality:     85,
	}
	imgBuf, err := imageutil.OptimizeImage(bytes.NewReader(raw.Bytes()), opt)
	if err != nil {
		return fiber.NewError(400, "invalid image")
	}

	ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
	if ext == "" {
		ext = ".png"
	}

	key := fmt.Sprintf("badges/%d/%d_%s%s",
		id,
		time.Now().Unix(),
		uuid.NewString(),
		ext,
	)

	ctx, cancel := context.WithTimeout(c.Context(), 10*time.Second)
	defer cancel()

	_, err = h.store.Put(
		ctx,
		key,
		bytes.NewReader(imgBuf.Bytes()),
		int64(imgBuf.Len()),
		"image/png",
	)
	if err != nil {
		return fiber.NewError(500, "upload failed: "+err.Error())
	}

	update := UpdateBadgeDTO{
		IconURL: &key,
	}

	_, err = h.svc.UpdateBadge(ctx, id, update)
	if err != nil {
		return fiber.NewError(500, err.Error())
	}

	presigned := generatePresigned(h.store, key)

	return c.JSON(fiber.Map{
		"success":  true,
		"badge_id": id,
		"key":      key,
		"url":      presigned,
	})
}
