package auth

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	api.Post("/register", h.Register)
	api.Post("/login", h.Login)
	api.Post("/refresh-token", h.GenerateRefreshToken)
}
