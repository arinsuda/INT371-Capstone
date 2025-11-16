package technicians

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	technicians := router.Group("/technicians")

	technicians.Get("/profile", h.GetProfile)
	technicians.Post("/profile", h.PostProfile)
	technicians.Patch("/profile", h.PostProfile)

	technicians.Patch("/provinces", h.PatchProvinces)
	technicians.Post("/:id/services", h.AddService)
	technicians.Delete("/:id/services", h.RemoveService)
}
