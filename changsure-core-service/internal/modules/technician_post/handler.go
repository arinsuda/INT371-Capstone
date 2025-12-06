package technicianposts

import (
	"context"
	"time"

	"changsure-core-service/pkg/utils"
	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc Service
}

func NewHandler(svc Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) CreatePost(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	var body CreateTechnicianPostDTO
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(400, "invalid body")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	res, err := h.svc.Create(ctx, techID, body)
	if err != nil {
		return fiber.NewError(500, err.Error())
	}

	return c.Status(201).JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) GetPost(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	postID, err := utils.ParseUintParam(c, "id")
	if err != nil || postID == 0 {
		return fiber.NewError(400, "invalid post id")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	res, err := h.svc.Get(ctx, techID, postID)
	if err != nil {
		return fiber.NewError(404, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) ListPosts(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	var q ListTechnicianPostsQuery
	if err := c.Bind().Query(&q); err != nil {
		return fiber.NewError(400, "invalid query")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	items, total, err := h.svc.List(ctx, techID, q)
	if err != nil {
		return fiber.NewError(500, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"items":    items,
			"page":     q.Page,
			"per_page": q.PerPage,
			"total":    total,
		},
	})
}

func (h *Handler) UpdatePost(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	postID, err := utils.ParseUintParam(c, "id")
	if err != nil || postID == 0 {
		return fiber.NewError(400, "invalid post id")
	}

	var body UpdateTechnicianPostDTO
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(400, "invalid body")
	}

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	res, err := h.svc.Update(ctx, techID, postID, body)
	if err != nil {
		return fiber.NewError(500, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) DeletePost(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	postID, err := utils.ParseUintParam(c, "id")
	if err != nil || postID == 0 {
		return fiber.NewError(400, "invalid post id")
	}

	hard := c.Query("hard") == "true"

	ctx, cancel := context.WithTimeout(c.Context(), 5*time.Second)
	defer cancel()

	if err := h.svc.Delete(ctx, techID, postID, hard); err != nil {
		return fiber.NewError(500, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "message": "post deleted"})
}
