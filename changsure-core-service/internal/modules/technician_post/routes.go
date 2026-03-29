package technicianposts

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	posts := router.Group("/:technicianID/posts")

	posts.Post("/", h.CreatePost)
	posts.Get("/", h.ListPosts)
	posts.Get("/reports", h.ListMyReports)
	posts.Get("/:postID", h.GetPost)
	posts.Put("/:postID", h.UpdatePost)
	posts.Delete("/:postID", h.DeletePost)
}

func (h *Handler) RegisterAdminRoutes(router fiber.Router) {
	posts := router.Group("/:technicianID/posts")
	posts.Get("/reports", h.ListReports)
	posts.Post("/:postID/report", h.ReportPost)
}

func (h *Handler) RegisterPublicRoutes(router fiber.Router) {
	router.Get("/report-types", h.GetReportTypes)
}
