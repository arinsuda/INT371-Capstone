package auth

import (
	appErr "changsure-core-service/internal/errors"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc Service
}

func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

// ===============================
// Register
// ===============================
func (h *Handler) Register(c fiber.Ctx) error {
	var req RegisterRequest

	// Parsing error
	if err := c.Bind().Body(&req); err != nil {
		return appErr.BadRequest(c, "Invalid request payload")
	}

	resp, err := h.svc.Register(c.Context(), req)
	if err != nil {

		switch err {
		case ErrEmailAlreadyExists:
			return appErr.Conflict(c, "Email already registered")

		case ErrInvalidRole:
			return appErr.BadRequest(c, "Invalid role")

		default:
			return appErr.InternalError(c, "Failed to register user", err)
		}
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data":    resp,
	})
}

// ===============================
// Login
// ===============================
func (h *Handler) Login(c fiber.Ctx) error {
	var req LoginRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErr.BadRequest(c, "Invalid request payload")
	}

	resp, err := h.svc.Login(c.Context(), req)
	if err != nil {
		switch err {
		case ErrInvalidCredentials:
			return appErr.Unauthorized(c, "Invalid email or password")

		default:
			return appErr.InternalError(c, "Failed to login", err)
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    resp,
	})
}

// ===============================
// GenerateRefreshToken
// ===============================
func (h *Handler) GenerateRefreshToken(c fiber.Ctx) error {
	var req RefreshRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErr.BadRequest(c, "Invalid request payload")
	}

	pair, err := h.svc.GenerateRefreshToken(c.Context(), req.RefreshToken)
	if err != nil {

		switch err {
		case ErrInvalidRefreshToken:
			return appErr.Unauthorized(c, "Invalid refresh token")

		case ErrRefreshTokenExpired:
			return appErr.Unauthorized(c, "Refresh token expired")

		default:
			return appErr.InternalError(c, "Failed to generate new tokens", err)
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    pair,
	})
}
