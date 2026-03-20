package auth

import (
	"errors"
	"net/http"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/validation"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) RegisterCustomer(c fiber.Ctx) error {
	var req RegisterCustomerRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(&req); err != nil {
		return appErrors.ValidationError(c, details)
	}
	resp, err := h.service.RegisterCustomer(c.Context(), req)
	if err != nil {
		return h.mapError(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) RegisterTechnician(c fiber.Ctx) error {
	var req RegisterTechnicianRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(&req); err != nil {
		return appErrors.ValidationError(c, details)
	}
	resp, err := h.service.RegisterTechnician(c.Context(), req)
	if err != nil {
		return h.mapError(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Login(c fiber.Ctx) error {
	var req LoginRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(&req); err != nil {
		return appErrors.ValidationError(c, details)
	}
	resp, err := h.service.Login(c.Context(), req)
	if err != nil {
		return h.mapError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) RefreshToken(c fiber.Ctx) error {
	var req RefreshTokenRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(&req); err != nil {
		return appErrors.ValidationError(c, details)
	}
	resp, err := h.service.RefreshToken(c.Context(), req)
	if err != nil {
		return h.mapError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) Logout(c fiber.Ctx) error {
	var req LogoutRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if details, err := validation.ValidateStruct(&req); err != nil {
		return appErrors.ValidationError(c, details)
	}
	if err := h.service.Logout(c.Context(), req); err != nil {
		return appErrors.InternalError(c, "failed to logout", err)
	}
	return c.JSON(fiber.Map{"success": true, "message": "logged out successfully"})
}

func (h *Handler) mapError(c fiber.Ctx, err error) error {
	var appErr *appErrors.AppError
	if !errors.As(err, &appErr) {
		return appErrors.InternalError(c, "unexpected error", err)
	}
	switch appErr.Code {
	case http.StatusConflict:
		return appErrors.Conflict(c, appErr.Message)
	case http.StatusUnauthorized:
		return appErrors.Unauthorized(c, appErr.Message)
	case http.StatusForbidden:
		return appErrors.Forbidden(c, appErr.Message)
	case http.StatusNotFound:
		return appErrors.NotFound(c, appErr.Message)
	default:
		return appErrors.InternalError(c, appErr.Message, err)
	}
}
