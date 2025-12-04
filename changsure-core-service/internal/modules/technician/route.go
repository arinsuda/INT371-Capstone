package technician

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/profile", h.GetProfile)
	router.Patch("/profile", h.UpdateProfile)

	router.Patch("/provinces", h.PatchProvinces)
	router.Post("/services", h.AddService)
	router.Delete("/services/:id", h.RemoveService)
	router.Patch("/services/:id", h.UpdateService)
	router.Post("/profile/avatar", h.UploadAvatar)
}
