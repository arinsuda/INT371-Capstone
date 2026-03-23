package technicianposts

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	posts := router.Group("/:technicianID/posts")

	posts.Post("/", h.CreatePost)
	posts.Get("/", h.ListPosts)
	posts.Get("/:id", h.GetPost)
	posts.Put("/:id", h.UpdatePost)
	posts.Delete("/:id", h.DeletePost)
}

func (h *Handler) RegisterAdminRoutes(router fiber.Router) {
	posts := router.Group("/:technicianID/posts")

	posts.Post("/:id/report", h.ReportPost)
	posts.Get("/reports", h.ListReports)
}
