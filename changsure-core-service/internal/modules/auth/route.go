package auth

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	g := api.Group("/auth")
	g.Post("/register", h.Register)
	g.Post("/login", h.Login)
	g.Post("/refresh", h.Refresh)
}
