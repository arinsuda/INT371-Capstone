package technician

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	technicians := router.Group("")

	technicians.Get("/profile", h.GetProfile)
	technicians.Patch("/profile", h.UpdateProfile)

	technicians.Patch("/provinces", h.PatchProvinces)
	technicians.Post("/:id/services", h.AddService)
	technicians.Delete("/:id/services", h.RemoveService)
	technicians.Patch("/services", h.UpdateService)
	technicians.Post("/profile/avatar", h.UploadAvatar)

}
