package notification

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(r fiber.Router) {
	grp := r.Group("/notifications")

	grp.Get("/", h.List)
	grp.Get("/unread-count", h.UnreadCount)
	grp.Patch("/read", h.MarkRead)
	grp.Patch("/read-all", h.ReadAll)
}
