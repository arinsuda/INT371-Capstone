package technicianposts

import (
	"context"
	"strconv"
	"strings"
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

	body.Title = c.FormValue("title")
	if desc := c.FormValue("description"); desc != "" {
		body.Description = &desc
	}

	if cid := c.FormValue("service_category_id"); cid != "" {
		if n, err := strconv.ParseUint(cid, 10, 64); err == nil {
			t := uint(n)
			body.ServiceCategoryID = &t
		}
	}

	// if sid := c.FormValue("service_id"); sid != "" {
	// 	if v, err := strconv.ParseUint(sid, 10, 64); err == nil {
	// 		tmp := uint(v)
	// 		body.ServiceID = &tmp
	// 	}
	// }

	// if pid := c.FormValue("province_id"); pid != "" {
	// 	if v, err := strconv.ParseUint(pid, 10, 64); err == nil {
	// 		tmp := uint(v)
	// 		body.ProvinceID = &tmp
	// 	}
	// }

	form, err := c.MultipartForm()
	if err == nil && form.File != nil {
		body.Images = form.File["images"]
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

	if title := c.FormValue("title"); title != "" {
		body.Title = &title
	}
	if desc := c.FormValue("description"); desc != "" {
		body.Description = &desc
	}

	if cid := c.FormValue("service_category_id"); cid != "" {
		if n, err := strconv.ParseUint(cid, 10, 64); err == nil {
			t := uint(n)
			body.ServiceCategoryID = &t
		}
	}

	// if sid := c.FormValue("service_id"); sid != "" {
	// 	if n, err := strconv.ParseUint(sid, 10, 64); err == nil {
	// 		t := uint(n)
	// 		body.ServiceID = &t
	// 	}
	// }

	// if pid := c.FormValue("province_id"); pid != "" {
	// 	if n, err := strconv.ParseUint(pid, 10, 64); err == nil {
	// 		t := uint(n)
	// 		body.ProvinceID = &t
	// 	}
	// }

	if pub := c.FormValue("is_published"); pub != "" {
		if parsed, err := strconv.ParseBool(pub); err == nil {
			body.IsPublished = &parsed
		}
	}

	form, err := c.MultipartForm()
	if err == nil && form.File != nil {
		body.NewImages = form.File["new_images"]
	}

	ids := c.FormValue("image_ids_to_delete")
	if ids != "" {
		for _, s := range strings.Split(ids, ",") {
			if n, err := strconv.ParseUint(s, 10, 64); err == nil {
				body.ImageIDsToDelete = append(body.ImageIDsToDelete, uint(n))
			}
		}
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
