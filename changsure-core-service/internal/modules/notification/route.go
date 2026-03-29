package notification

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	noti := api.Group("/notifications")

	noti.Get("/", h.List)
	noti.Get("/:id", h.Get)
	noti.Patch("/", h.PatchBulk)
	noti.Patch("/:id", h.Patch)
}
