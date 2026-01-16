package technicianposts

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(router fiber.Router) {
	router.Post("/posts", h.CreatePost)
	router.Get("/posts", h.ListPosts)
	router.Get("/posts/:id", h.GetPost)
	router.Put("/posts/:id", h.UpdatePost)
	router.Delete("/posts/:id", h.DeletePost)
}

func (h *Handler) RegisterPublicRoutes(router fiber.Router) {
	router.Get("/:technician_id/posts", h.ListPublicPosts)
	router.Get("/:technician_id/posts/:id", h.GetPublicPost)
}
