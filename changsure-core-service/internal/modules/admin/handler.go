package admin

import (
	"context"
	"strconv"

	appErrors "changsure-core-service/internal/errors"

	"github.com/gofiber/fiber/v3"
)

var allowedMimeTypes = map[string]bool{
	"image/jpeg": true,
	"image/png":  true,
	"image/webp": true,
}

const maxAvatarSize = 5 * 1024 * 1024

type Handler struct {
	svc Service
}

func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	adminID, err := parseID(c)
	if err != nil {
		return appErrors.BadRequest(c, "invalid admin id")
	}

	req := SetupProfileRequest{
		FirstName: c.FormValue("first_name"),
		LastName:  c.FormValue("last_name"),
	}
	if req.FirstName == "" || req.LastName == "" {
		return appErrors.BadRequest(c, "first_name and last_name are required")
	}

	var avatarFile *AvatarFile
	if file, err := c.FormFile("avatar"); err == nil {
		if file.Size > maxAvatarSize {
			return appErrors.BadRequest(c, "avatar must not exceed 5MB")
		}
		contentType := file.Header.Get("Content-Type")
		if !allowedMimeTypes[contentType] {
			return appErrors.BadRequest(c, "avatar must be jpeg, png or webp")
		}
		src, err := file.Open()
		if err != nil {
			return appErrors.HandleError(c, err)
		}
		defer src.Close()
		avatarFile = &AvatarFile{
			Reader:      src,
			Size:        file.Size,
			ContentType: contentType,
		}
	}

	profile, err := h.svc.UpdateProfile(context.Background(), adminID, req, avatarFile)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(profile)
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
	adminID, err := parseID(c)
	if err != nil {
		return appErrors.BadRequest(c, "invalid admin id")
	}

	profile, err := h.svc.GetProfile(context.Background(), adminID)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(profile)
}

func (h *Handler) UpdateAvatar(c fiber.Ctx) error {
	adminID, err := parseID(c)
	if err != nil {
		return appErrors.BadRequest(c, "invalid admin id")
	}

	file, err := c.FormFile("avatar")
	if err != nil {
		return appErrors.BadRequest(c, "avatar file is required (field: avatar)")
	}
	if file.Size > maxAvatarSize {
		return appErrors.BadRequest(c, "avatar must not exceed 5MB")
	}
	contentType := file.Header.Get("Content-Type")
	if !allowedMimeTypes[contentType] {
		return appErrors.BadRequest(c, "avatar must be jpeg, png or webp")
	}

	src, err := file.Open()
	if err != nil {
		return appErrors.HandleError(c, err)
	}
	defer src.Close()

	profile, err := h.svc.UpdateAvatar(context.Background(), adminID, src, file.Size, contentType)
	if err != nil {
		return appErrors.HandleError(c, err)
	}

	return c.Status(fiber.StatusOK).JSON(profile)
}

func parseID(c fiber.Ctx) (uint, error) {
	id, err := strconv.ParseUint(c.Params("id"), 10, 64)
	if err != nil {
		return 0, err
	}
	return uint(id), nil
}
