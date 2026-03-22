package technician

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Get("/:technicianID", h.GetProfile)
	router.Patch("/:technicianID", h.UpdateProfile)
	router.Patch("/:technicianID/avatar", h.UploadAvatar)
	router.Put("/:technicianID/provinces", h.PatchProvinces)

	router.Post("/:technicianID/services", h.AddService)
	router.Patch("/:technicianID/services/:serviceID", h.UpdateService)
	router.Delete("/:technicianID/services/:serviceID", h.RemoveService)
}

func (h *Handler) RegisterAdminRoutes(router fiber.Router) {
	router.Get("/technicians", h.ListTechnicians)
}
