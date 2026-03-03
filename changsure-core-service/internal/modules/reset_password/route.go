package resetpassword

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(r fiber.Router) {
	pwd := r.Group("/password-resets")

	pwd.Post("/", h.ForgotPassword)
	pwd.Post("/verify", h.VerifyOTP)
	pwd.Patch("/", h.ResetPassword)
}
