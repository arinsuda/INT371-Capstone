package technicians

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(router fiber.Router) {
	technicians := router.Group("/technicians")

	// สร้าง/อัปเดตโปรไฟล์ช่าง
	technicians.Get("/profile", h.GetProfile)
	technicians.Post("/profile", h.PostProfile)
	technicians.Patch("/profile", h.PostProfile)

	technicians.Patch("/provinces", h.PatchProvinces)

	// (เพิ่มในอนาคต)
	// technicians.Get("/", h.ListTechnicians)
	// technicians.Get("/:id", h.GetTechnician)
	// technicians.Patch("/:id", h.UpdateTechnician)
	// technicians.Delete("/:id", h.DeleteTechnician)
}
