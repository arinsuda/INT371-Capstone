package admin

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(r fiber.Router) {
	r.Get("/:id/profile", h.GetProfile)
	r.Put("/:id/profile", h.UpdateProfile)
	r.Patch("/:id/avatar", h.UpdateAvatar)
}
