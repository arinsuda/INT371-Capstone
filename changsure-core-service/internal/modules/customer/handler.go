package customers

import (
	"errors"
	"fmt"
	"log/slog"
	"path/filepath"
	"strconv"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
)

const (
	AvatarFolderPrefix = "avatars/customers"
	FormKeyAvatar      = "avatar"
)

type Handler struct {
	service Service
	storage storage.Storage
	logger  *slog.Logger
}

func NewHandler(service Service, s storage.Storage, logger *slog.Logger) *Handler {
	return &Handler{
		service: service,
		storage: s,
		logger:  logger,
	}
}

func (h *Handler) processAvatarUpload(c fiber.Ctx, userID uint) (*string, error) {
	fileHeader, err := c.FormFile(FormKeyAvatar)
	if err != nil {

		return nil, nil
	}

	file, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	contentType := fileHeader.Header.Get("Content-Type")

	ext := filepath.Ext(fileHeader.Filename)
	fileName := fmt.Sprintf("%s%s", uuid.New().String(), ext)

	folder := fmt.Sprintf("%s/%d", AvatarFolderPrefix, userID)

	key, err := h.storage.UploadFile(
		c.Context(),
		file,
		fileName,
		folder,
		fileHeader.Size,
		contentType,
	)

	if err != nil {
		return nil, err
	}

	return &key, nil
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
	id := utils.GetUserID(c)
	if id == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), id)

	resp, err := h.service.GetProfile(ctx, id)
	if err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return appErrors.NotFound(c, "profile not found")
		}

		h.logger.Error("failed to get profile", "user_id", id, "error", err)
		return appErrors.InternalError(c, "failed to get profile", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	id := utils.GetUserID(c)
	if id == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req UpdateCustomerRequest

	if err := c.Bind().Body(&req); err != nil {
		h.logger.Warn("invalid request body in UpdateProfile", "user_id", id, "error", err)
		return appErrors.BadRequest(c, "invalid request body")
	}

	avatarKey, err := h.processAvatarUpload(c, id)
	if err != nil {
		h.logger.Error("failed to upload avatar in UpdateProfile", "user_id", id, "error", err)
		return appErrors.InternalError(c, "failed to upload avatar", err)
	}

	if avatarKey != nil {
		req.AvatarURL = avatarKey
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), id)

	resp, err := h.service.UpdateProfile(ctx, id, &req)
	if err != nil {
		switch {
		case errors.Is(err, ErrCustomerNotFound):
			return appErrors.NotFound(c, "profile not found")
		case errors.Is(err, ErrPhoneAlreadyExists):
			return appErrors.Conflict(c, "phone number already in use")
		case errors.Is(err, ErrEmailAlreadyExists):
			return appErrors.Conflict(c, "email already in use")
		default:
			h.logger.Error("service failed to update profile", "user_id", id, "error", err)
			return appErrors.InternalError(c, "failed to update profile", err)
		}
	}

	h.logger.Info("profile updated successfully", "user_id", id)
	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) UpdateCustomer(c fiber.Ctx) error {

	targetID, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	var req UpdateCustomerRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	avatarKey, err := h.processAvatarUpload(c, targetID)
	if err != nil {
		h.logger.Error("admin failed to upload avatar", "target_id", targetID, "error", err)
		return appErrors.InternalError(c, "failed to upload avatar", err)
	}
	if avatarKey != nil {
		req.AvatarURL = avatarKey
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	resp, err := h.service.Update(c.Context(), targetID, &req)
	if err != nil {
		switch {
		case errors.Is(err, ErrCustomerNotFound):
			return appErrors.NotFound(c, "customer not found")
		case errors.Is(err, ErrPhoneAlreadyExists):
			return appErrors.Conflict(c, "phone number already in use")
		case errors.Is(err, ErrEmailAlreadyExists):
			return appErrors.Conflict(c, "email already in use")
		default:
			h.logger.Error("admin failed to update customer", "target_id", targetID, "error", err)
			return appErrors.InternalError(c, "failed to update customer", err)
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "customer updated successfully",
		"data":    resp,
	})
}

func (h *Handler) GetCustomer(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	resp, err := h.service.GetByID(c.Context(), id)
	if err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return appErrors.NotFound(c, "customer not found")
		}
		h.logger.Error("failed to get customer by id", "id", id, "error", err)
		return appErrors.InternalError(c, "failed to get customer", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) ListCustomers(c fiber.Ctx) error {
	pageStr := c.Query("page")
	pageSizeStr := c.Query("page_size")

	page := 1
	pageSize := 20

	if pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	if pageSizeStr != "" {
		if s, err := strconv.Atoi(pageSizeStr); err == nil && s > 0 {
			pageSize = s
		}
	}

	list, err := h.service.List(c.Context(), page, pageSize)
	if err != nil {
		h.logger.Error("failed to list customers", "error", err)
		return appErrors.InternalError(c, "failed to list customers", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"customers": list,
			"page":      page,
			"total":     len(list),
		},
	})
}

func (h *Handler) DeleteCustomer(c fiber.Ctx) error {
	id, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := h.service.Delete(c.Context(), id); err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return appErrors.NotFound(c, "customer not found")
		}
		h.logger.Error("failed to delete customer", "id", id, "error", err)
		return appErrors.InternalError(c, "failed to delete customer", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "customer deleted successfully",
	})
}
