package customer

import (
	"errors"
	"fmt"
	"log/slog"
	"path/filepath"
	"strconv"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/internal/validation"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
	"github.com/google/uuid"
)

const (
	avatarFolderPrefix = "avatars/customers"
	formKeyAvatar      = "avatar"
)

type Handler struct {
	service Service
	storage storage.Storage
	logger  *slog.Logger
}

func NewHandler(service Service, s storage.Storage, logger *slog.Logger) *Handler {
	return &Handler{service: service, storage: s, logger: logger}
}

func (h *Handler) GetCustomer(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	ctx := utils.InjectUserIDIntoContext(c.Context(), customerID)

	resp, err := h.service.GetByID(ctx, customerID)
	if err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return appErrors.NotFound(c, "customer not found")
		}
		h.logger.Error("failed to get customer", "customer_id", customerID, "error", err)
		return appErrors.InternalError(c, "failed to get customer", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) UpdateCustomer(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, customerID); err != nil {
		return appErrors.HandleError(c, err)

	}

	var req UpdateCustomerRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	avatarKey, err := h.processAvatarUpload(c, customerID)
	if err != nil {
		h.logger.Error("failed to upload avatar", "customer_id", customerID, "error", err)
		return appErrors.InternalError(c, "failed to upload avatar", err)
	}
	if avatarKey != nil {
		req.AvatarURL = avatarKey
	}

	if details, err := validation.ValidateStruct(req); err != nil {
		return appErrors.ValidationError(c, details)
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	resp, err := h.service.Update(ctx, customerID, &req)
	if err != nil {
		switch {
		case errors.Is(err, ErrCustomerNotFound):
			return appErrors.NotFound(c, "customer not found")
		case errors.Is(err, ErrPhoneAlreadyExists):
			return appErrors.Conflict(c, "phone number already in use")
		case errors.Is(err, ErrEmailAlreadyExists):
			return appErrors.Conflict(c, "email already in use")
		default:
			h.logger.Error("failed to update customer", "customer_id", customerID, "error", err)
			return appErrors.InternalError(c, "failed to update customer", err)
		}
	}

	h.logger.Info("customer updated", "customer_id", customerID, "by", callerID)
	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) ListCustomers(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	page, pageSize := parsePagination(c)

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
			"page_size": pageSize,
			"total":     len(list),
		},
	})
}

func (h *Handler) DeleteCustomer(c fiber.Ctx) error {
	customerID, err := utils.ParseUintParam(c, "customerID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid customer id")
	}

	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}

	if err := h.service.Delete(c.Context(), customerID); err != nil {
		if errors.Is(err, ErrCustomerNotFound) {
			return appErrors.NotFound(c, "customer not found")
		}
		h.logger.Error("failed to delete customer", "customer_id", customerID, "error", err)
		return appErrors.InternalError(c, "failed to delete customer", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "customer deleted successfully"})
}

func (h *Handler) processAvatarUpload(c fiber.Ctx, userID uint) (*string, error) {
	fileHeader, err := c.FormFile(formKeyAvatar)
	if err != nil {
		return nil, nil
	}

	file, err := fileHeader.Open()
	if err != nil {
		return nil, fmt.Errorf("failed to open uploaded file: %w", err)
	}
	defer file.Close()

	ext := filepath.Ext(fileHeader.Filename)
	fileName := fmt.Sprintf("%s%s", uuid.New().String(), ext)
	folder := fmt.Sprintf("%s/%d", avatarFolderPrefix, userID)
	contentType := fileHeader.Header.Get("Content-Type")

	key, err := h.storage.UploadFile(c.Context(), file, fileName, folder, fileHeader.Size, contentType)
	if err != nil {
		return nil, fmt.Errorf("failed to upload avatar: %w", err)
	}

	return &key, nil
}

func parsePagination(c fiber.Ctx) (page, pageSize int) {
	page, pageSize = 1, 20
	if p, err := strconv.Atoi(c.Query("page")); err == nil && p > 0 {
		page = p
	}
	if s, err := strconv.Atoi(c.Query("page_size")); err == nil && s > 0 {
		pageSize = s
	}
	return
}
