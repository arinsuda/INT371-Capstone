package resetpassword

import (
	"errors"

	appErrors "changsure-core-service/internal/errors"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	service Service
}

func NewHandler(s Service) *Handler {
	return &Handler{service: s}
}

func (h *Handler) ForgotPassword(c fiber.Ctx) error {
	var req ForgotPasswordRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	resp, err := h.service.ForgotPassword(req)
	if err != nil {
		switch {
		case errors.Is(err, ErrEmailNotFound):
			return c.JSON(fiber.Map{
				"message":    "หากอีเมลนี้มีในระบบ เราจะส่งรหัส OTP ไปให้",
				"expires_in": int(otpTTL.Seconds()),
			})
		case errors.Is(err, ErrGoogleAccountOnly):
			return appErrors.BadRequest(c, "บัญชีนี้ใช้ Google Login กรุณาเข้าสู่ระบบด้วย Google")
		default:
			return appErrors.InternalError(c, "failed to process request", err)
		}
	}

	return c.JSON(resp)
}

func (h *Handler) VerifyOTP(c fiber.Ctx) error {
	var req VerifyOTPRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	resp, err := h.service.VerifyOTP(req)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidOTP):
			return appErrors.BadRequest(c, "รหัส OTP ไม่ถูกต้องหรือหมดอายุแล้ว")
		default:
			return appErrors.InternalError(c, "failed to verify OTP", err)
		}
	}

	return c.JSON(resp)
}

func (h *Handler) ResetPassword(c fiber.Ctx) error {
	var req ResetPasswordRequest
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	resp, err := h.service.ResetPassword(req)
	if err != nil {
		switch {
		case errors.Is(err, ErrInvalidToken):
			return appErrors.BadRequest(c, "reset token ไม่ถูกต้องหรือหมดอายุแล้ว")
		case errors.Is(err, ErrEmailNotFound):
			return appErrors.NotFound(c, "user not found")
		default:
			return appErrors.InternalError(c, "failed to reset password", err)
		}
	}

	return c.JSON(resp)
}
