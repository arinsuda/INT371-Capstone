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
	svc Service
}

func NewIconHandler(svc Service) *IconHandler {
	return &IconHandler{svc: svc}
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

	key := fmt.Sprintf(
		"badges/%d/%d_%s%s",
		id,
		time.Now().Unix(),
		uuid.NewString(),
		ext,
	)

	contentType := fileHeader.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	ctx, cancel := context.WithTimeout(c.Context(), 15*time.Second)
	defer cancel()

	_, err = storage.GlobalMinio.Put(
		ctx,
		key,
		f,
		fileHeader.Size,
		contentType,
	)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "upload error: "+err.Error())
	}

	patch := UpdateBadgeDTO{IconURL: &key}
	if _, err := h.svc.UpdateBadge(ctx, id, patch); err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, err.Error())
	}

	iconPresigned, err := storage.GlobalMinio.PresignGet(
		ctx,
		key,
		time.Hour,
		false,
	)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "failed to generate icon URL")
	}

	return c.Status(fiber.StatusOK).JSON(fiber.Map{
		"id":       id,
		"icon_key": key,
		"icon_url": iconPresigned,
	})
}

func (h *IconHandler) GetIconURL(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return fiber.NewError(fiber.StatusBadRequest, "invalid id")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	badge, err := h.svc.FindBadge(ctx, id, true)
	if err != nil {
		return fiber.NewError(fiber.StatusNotFound, "badge not found")
	}
	if badge.IconURL == "" {
		return fiber.NewError(fiber.StatusNotFound, "icon not set")
	}

	iconURL, err := storage.GlobalMinio.PresignGet(
		ctx,
		badge.IconURL,
		time.Hour,
		false,
	)
	if err != nil {
		return fiber.NewError(fiber.StatusInternalServerError, "failed to generate icon URL")
	}

	return c.JSON(fiber.Map{
		"id":       badge.ID,
		"icon_url": iconURL,
	})
}
