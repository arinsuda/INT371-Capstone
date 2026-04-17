package auth

import (
	"changsure-core-service/internal/config"
	"changsure-core-service/internal/middleware"
	emailverification "changsure-core-service/internal/modules/email_verification"

	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router, cfg *config.Config, evHandler *emailverification.Handler) {
	g := r.Group("/auth")

	g.Post("/customer/register", h.RegisterCustomer)
	g.Post("/technician/register", h.RegisterTechnician)
	g.Post("/login", h.Login)
	g.Post("/refresh", h.RefreshToken)
	g.Post("/logout", h.Logout)

	preVerified := g.Group("", middleware.PreVerifiedAuth(cfg.JWT.Secret))
	preVerified.Post("/email/verify", evHandler.VerifyOTP)
	preVerified.Post("/email/resend", evHandler.ResendOTP)
}
