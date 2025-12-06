package technician

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {

	technician := router.Group("/me")

	technician.Get("/profile", h.GetProfile)
	technician.Patch("/profile", h.UpdateProfile)

	technician.Patch("/provinces", h.PatchProvinces)
	technician.Post("/services", h.AddService)
	technician.Delete("/services/:id", h.RemoveService)
	technician.Patch("/services/:id", h.UpdateService)
	technician.Patch("/profile/avatar", h.UploadAvatar)
}
