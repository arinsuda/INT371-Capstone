package emailverification

// import (
// 	"errors"

// 	appErrors "changsure-core-service/internal/errors"
// 	"changsure-core-service/internal/middleware"
// 	"changsure-core-service/internal/validation"

// 	"github.com/gofiber/fiber/v3"
// )

// type Handler struct {
// 	svc Service
// }

// func NewHandler(svc Service) *Handler {
// 	return &Handler{svc: svc}
// }

// // VerifyOTP POST /auth/verify-email
// // ใช้ pre_verified_token (scope=pending_verification) เรียก endpoint นี้
// func (h *Handler) VerifyOTP(c fiber.Ctx) error {
// 	userID, ok := middleware.GetUserID(c)
// 	if !ok {
// 		return appErrors.Unauthorized(c, "unauthorized")
// 	}
// 	_ = userID

// 	role, ok := c.Locals("role").(string)
// 	if !ok {
// 		return appErrors.Unauthorized(c, "unauthorized")
// 	}

// 	email, ok := c.Locals("email").(string)
// 	if !ok || email == "" {
// 		return appErrors.Unauthorized(c, "email not found in token")
// 	}

// 	var req VerifyOTPRequest
// 	if err := c.Bind().Body(&req); err != nil {
// 		return appErrors.BadRequest(c, "invalid request body")
// 	}
// 	if details, err := validation.ValidateStruct(&req); err != nil {
// 		return appErrors.ValidationError(c, details)
// 	}

// 	if err := h.svc.VerifyOTP(c.Context(), email, role, req.OTP); err != nil {
// 		var appErr *appErrors.AppError
// 		if errors.As(err, &appErr) {
// 			return appErrors.HandleError(c, err)
// 		}
// 		return appErrors.InternalError(c, "failed to verify OTP", err)
// 	}

// 	return c.JSON(fiber.Map{
// 		"success": true,
// 		"data": fiber.Map{
// 			"message":           "ยืนยัน email สำเร็จ กรุณา login อีกครั้ง",
// 			"is_email_verified": true,
// 		},
// 	})
// }

// // ResendOTP POST /auth/resend-otp
// // ใช้ pre_verified_token เรียก endpoint นี้
// func (h *Handler) ResendOTP(c fiber.Ctx) error {
// 	userID, ok := middleware.GetUserID(c)
// 	if !ok {
// 		return appErrors.Unauthorized(c, "unauthorized")
// 	}

// 	role, ok := c.Locals("role").(string)
// 	if !ok {
// 		return appErrors.Unauthorized(c, "unauthorized")
// 	}

// 	email, ok := c.Locals("email").(string)
// 	if !ok || email == "" {
// 		return appErrors.Unauthorized(c, "email not found in token")
// 	}

// 	resp, err := h.svc.IssueOTP(c.Context(), userID, email, role)
// 	if err != nil {
// 		var appErr *appErrors.AppError
// 		if errors.As(err, &appErr) {
// 			return appErrors.HandleError(c, err)
// 		}
// 		return appErrors.InternalError(c, "failed to resend OTP", err)
// 	}

// 	return c.JSON(fiber.Map{"success": true, "data": resp})
// }