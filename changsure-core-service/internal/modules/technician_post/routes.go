package technicianposts

import "github.com/gofiber/fiber/v3"

func (h *Handler) RegisterRoutes(api fiber.Router) {
	me := api.Group("/me")

	me.Post("/posts", h.CreatePost)
	me.Get("/posts", h.ListPosts)
	me.Get("/posts/:id", h.GetPost)
	me.Put("/posts/:id", h.UpdatePost)
	me.Delete("/posts/:id", h.DeletePost)
}
