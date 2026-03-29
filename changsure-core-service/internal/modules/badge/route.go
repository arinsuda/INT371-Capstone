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
	svc := NewService(repo, store)

	return &RouteBundle{
		h: NewHandler(svc, store),
	}
}

func (rb *RouteBundle) RegisterRoutes(api fiber.Router) {
	badges := api.Group("/badges")

	badges.Post("/", rb.h.CreateBadge)
	badges.Get("/", rb.h.ListBadges)
	badges.Get("/:badgeID", rb.h.GetBadge)
	badges.Put("/:badgeID/icon", rb.h.UploadIcon)
	badges.Put("/:badgeID", rb.h.UpdateBadge)
	badges.Delete("/:badgeID", rb.h.DeleteBadge)
	badges.Patch("/:badgeID", rb.h.RestoreBadge)
}
