package badge

import (
	"changsure-core-service/pkg/storage"
	"github.com/gofiber/fiber/v3"
	"gorm.io/gorm"
)

type RouteBundle struct {
	h *Handler
}

func NewRouteBundle(db *gorm.DB, store *storage.MinioStorage) *RouteBundle {
	repo := NewRepository(db)
	svc := NewService(repo)

	return &RouteBundle{
		h: NewHandler(svc, store),
	}
}

func (rb *RouteBundle) RegisterRoutes(api fiber.Router) {
	badges := api.Group("/badges")

	badges.Post("/", rb.h.CreateBadge)

	badges.Get("/", rb.h.ListBadges)
	badges.Get("/:id", rb.h.GetBadge)
	badges.Put("/:id", rb.h.UpdateBadge)
	badges.Delete("/:id", rb.h.DeleteBadge)
	badges.Patch("/:id/restore", rb.h.RestoreBadge)

	badges.Put("/:id/icon", rb.h.UploadIcon)
}
