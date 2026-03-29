package auth

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(r fiber.Router) {
	g := r.Group("/auth")

	g.Post("/customer/register", h.RegisterCustomer)
	g.Post("/technician/register", h.RegisterTechnician)
	g.Post("/login", h.Login)
	g.Post("/refresh", h.RefreshToken)
	g.Post("/logout", h.Logout)
}
