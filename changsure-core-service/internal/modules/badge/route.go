package badge

import (
	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"

	"changsure-core-service/pkg/storage"
)

type RouteBundle struct {
	h  *Handler
	ih *IconHandler
}

func NewRouteBundle(db *gorm.DB, store *storage.MinioStorage) *RouteBundle {
	repo := NewRepository(db)
	svc := NewService(repo)

	return &RouteBundle{
		h:  NewHandler(svc),
		ih: NewIconHandler(svc, store),
	}
}

func (rb *RouteBundle) RegisterRoutes(api fiber.Router) {
	g := api.Group("/badges")

	g.Post("/", rb.h.Create)
	g.Get("/", rb.h.List)
	g.Get("/:id", rb.h.Get)
	g.Patch("/:id", rb.h.Update)
	g.Delete("/:id", rb.h.Delete)
	g.Post("/:id/restore", rb.h.Restore)

	g.Patch("/:id/icon", rb.ih.UploadIcon)
	g.Get("/:id/icon-url", rb.ih.GetIconURL)
}
