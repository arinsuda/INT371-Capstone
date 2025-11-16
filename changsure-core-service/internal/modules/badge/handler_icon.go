package badge

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"

	"changsure-core-service/pkg/storage"
	utils "changsure-core-service/pkg/utils"
)

type IconHandler struct {
	svc   Service
	store *storage.MinioStorage
}

func NewIconHandler(svc Service, store *storage.MinioStorage) *IconHandler {
	return &IconHandler{svc: svc, store: store}
}

func (h *IconHandler) UploadIcon(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid id")
	}

	fileHeader, err := c.FormFile("file")
	if err != nil || fileHeader == nil {
		return fiber.NewError(fiber.StatusBadRequest, "file is required")
	}

	f, err := fileHeader.Open()
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "cannot open file")
	}
	defer f.Close()

	ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
	if ext == "" {
		ext = ".png"
	}
	key := fmt.Sprintf("badges/%d/%d_%s%s", id, time.Now().Unix(), uuid.NewString(), ext)

	contentType := fileHeader.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	if _, err := h.store.Put(ctx, key, f, fileHeader.Size, contentType); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "upload error: "+err.Error())
	}

	b, err := h.svc.Get(ctx, id, true)
	if err != nil {
		return fiber.NewError(fiber.StatusNotFound, "badge not found")
	}
	patch := UpdateBadgeDTO{IconURL: &key}
	if _, err := h.svc.Update(ctx, id, patch); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	presigned, err := h.store.PresignGet(ctx, key, 24*time.Hour, false)
	if err != nil {

		return c.Status(fiber.StatusOK).JSON(fiber.Map{
			"id":       b.ID,
			"icon_key": key,
			"icon_url": "",
			"message":  "uploaded, but presign failed (use separate endpoint to fetch URL)",
		})
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"id":       b.ID,
		"icon_key": key,
		"icon_url": presigned,
	})
}

func (h *IconHandler) GetIconURL(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid id")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	b, err := h.svc.Get(ctx, id, true)
	if err != nil {
		return fiber.NewError(fiber.StatusNotFound, "badge not found")
	}
	if b.IconURL == "" {
		return fiber.NewError(fiber.StatusNotFound, "icon not set")
	}

	url, err := h.store.PresignGet(ctx, b.IconURL, 15*time.Minute, false)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "presign error: "+err.Error())
	}
	return c.JSON(fiber.Map{
		"id":       b.ID,
		"icon_url": url,
	})
}
