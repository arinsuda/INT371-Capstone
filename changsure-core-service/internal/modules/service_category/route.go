package servicecategory

import (
	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {
	g := r.Group("/service-categories")

	g.Get("/", h.ListServiceCategories)
	g.Get("/:id", h.GetServiceCategoryById)
	g.Post("/", h.CreateServiceCategory)
	g.Put("/:id", h.UpdateServiceCategory)
	g.Delete("/:id", h.DeleteServiceCategoryById)
	g.Post("/:id/icon", h.UploadIconServiceCategory)
}
