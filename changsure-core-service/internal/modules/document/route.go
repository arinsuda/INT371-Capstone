package document

import (
	"changsure-core-service/internal/middleware"

	"github.com/gofiber/fiber/v3"
)

func (h *Handler) RegisterRoutes(r fiber.Router) {
	docs := r.Group("/documents")
	docs.Get("/:slug", h.GetPublished)
	// docs.Post("/:slug/acceptances", h.Accept)

	admin := docs.Group("/admin", middleware.AdminOnly())
	admin.Post("/", h.CreateDocument)
	admin.Post("/:slug/versions", h.CreateVersion)
	admin.Patch("/:slug/versions/:version/publish", h.Publish)
}
