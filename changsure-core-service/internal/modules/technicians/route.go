package technicians

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	technicians := router.Group("")

	technicians.Get("/profile", h.GetProfile)
	technicians.Patch("/profile", h.UpdateProfile)

	technicians.Patch("/provinces", h.PatchProvinces)
	technicians.Post("/services", h.AddService)
	technicians.Delete("/services", h.RemoveService)
	technicians.Post("/profile/avatar", h.UploadAvatar)
	technicians.Put("/services/:service_id", h.UpdateService)

}
