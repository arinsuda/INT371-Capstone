package technicianposts

import (
	"errors"
	"strconv"
	"strings"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
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
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}
	body, err := bindCreateDTO(c)
	if err != nil {
		return appErrors.BadRequest(c, err.Error())
	}
	res, err := h.svc.Create(c.Context(), techID, body)
	if err != nil {
		return appErrors.HandleError(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) GetPost(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	postID, err := parseUintParam(c, "postID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid post id")
	}
	res, err := h.svc.Get(c.Context(), techID, postID)
	if err != nil {
		return appErrors.HandleError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) ListPosts(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	var q ListTechnicianPostsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query")
	}
	q.SetDefaults()
	result, err := h.svc.List(c.Context(), techID, q)
	if err != nil {
		return appErrors.HandleError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "data": result})
}

func (h *Handler) UpdatePost(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}
	postID, err := parseUintParam(c, "postID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid post id")
	}
	body, err := bindUpdateDTO(c)
	if err != nil {
		return appErrors.BadRequest(c, err.Error())
	}
	res, err := h.svc.Update(c.Context(), techID, postID, body)
	if err != nil {
		return appErrors.HandleError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) DeletePost(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}
	postID, err := parseUintParam(c, "postID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid post id")
	}
	hard := c.Query("hard") == "true"
	if err := h.svc.Delete(c.Context(), techID, postID, hard); err != nil {
		return appErrors.HandleError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "message": "post deleted"})
}

func (h *Handler) GetReportTypes(c fiber.Ctx) error {
	return c.JSON(fiber.Map{
		"success": true,
		"data": []string{
			ReportTypeInappropriateImage,
			ReportTypeCopyrightViolation,
			ReportTypeUnrelatedImage,
			ReportTypeLowQualityImage,
			ReportTypeDuplicateImage,
			ReportTypeExaggeratedWork,
			ReportTypeIncorrectInfo,
			ReportTypeMisleadingDescription,
			ReportTypeExternalContact,
			ReportTypePersonalDataExposed,
		},
	})
}

func (h *Handler) ListReports(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	var q ListPostReportsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query")
	}
	q.SetDefaults()

	result, err := h.svc.ListReports(c.Context(), techID, q, true)
	if err != nil {
		return appErrors.HandleError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "data": result})
}

func (h *Handler) ReportPost(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	postID, err := parseUintParam(c, "postID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid post id")
	}

	adminID, ok := middleware.GetUserID(c)
	if !ok || adminID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	var req CreatePostReportDTO
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	if req.ReportType == "" {
		return appErrors.BadRequest(c, "report_type is required")
	}
	if !IsValidReportType(req.ReportType) {
		return appErrors.BadRequest(c, "invalid report_type")
	}
	if req.Severity != ReportSeverityWarning && req.Severity != ReportSeverityBlacklist {
		return appErrors.BadRequest(c, "severity must be WARNING or BLACKLIST")
	}

	res, err := h.svc.ReportPost(c.Context(), techID, postID, adminID, req)
	if err != nil {
		
		
		var bannedErr *BannedError
		if errors.As(err, &bannedErr) {
			return c.Status(fiber.StatusConflict).JSON(fiber.Map{
				"success": false,
				"message": "ช่างคนนี้อยู่ในสถานะ Blacklist แล้ว ไม่สามารถ report ซ้ำได้",
				"data": fiber.Map{
					"blacklisted":       true,
					"technician_id":     bannedErr.Info.TechnicianID,
					"banned_at":         bannedErr.Info.BannedAt,
					"expires_at":        bannedErr.Info.ExpiresAt,
					"remaining_days":    bannedErr.Info.RemainingDays,
					"remaining_hours":   bannedErr.Info.RemainingHours,
					"remaining_minutes": bannedErr.Info.RemainingMinutes,
				},
			})
		}
		return appErrors.HandleError(c, err)
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) ListMyReports(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}
	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var q ListPostReportsQuery
	if err := c.Bind().Query(&q); err != nil {
		return appErrors.BadRequest(c, "invalid query")
	}
	q.SetDefaults()

	result, err := h.svc.ListReports(c.Context(), techID, q, false)
	if err != nil {
		return appErrors.HandleError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "data": result})
}

func bindCreateDTO(c fiber.Ctx) (CreateTechnicianPostDTO, error) {
	var dto CreateTechnicianPostDTO
	dto.Title = c.FormValue("title")
	if desc := c.FormValue("description"); desc != "" {
		dto.Description = &desc
	}
	if v := parseOptionalUint(c.FormValue("service_category_id")); v != nil {
		dto.ServiceCategoryID = v
	}
	if form, err := c.MultipartForm(); err == nil && form.File != nil {
		dto.Images = form.File["images"]
	}
	return dto, nil
}

func bindUpdateDTO(c fiber.Ctx) (UpdateTechnicianPostDTO, error) {
	var dto UpdateTechnicianPostDTO
	if title := c.FormValue("title"); title != "" {
		dto.Title = &title
	}
	if desc := c.FormValue("description"); desc != "" {
		dto.Description = &desc
	}
	if v := parseOptionalUint(c.FormValue("service_category_id")); v != nil {
		dto.ServiceCategoryID = v
	}
	if pub := c.FormValue("is_published"); pub != "" {
		if b, err := strconv.ParseBool(pub); err == nil {
			dto.IsPublished = &b
		}
	}
	if form, err := c.MultipartForm(); err == nil && form.File != nil {
		dto.NewImages = form.File["new_images"]
	}
	if ids := c.FormValue("image_ids_to_delete"); ids != "" {
		for _, s := range strings.Split(ids, ",") {
			if n, err := strconv.ParseUint(strings.TrimSpace(s), 10, 64); err == nil {
				dto.ImageIDsToDelete = append(dto.ImageIDsToDelete, uint(n))
			}
		}
	}
	return dto, nil
}

func parseOptionalUint(s string) *uint {
	if s == "" {
		return nil
	}
	n, err := strconv.ParseUint(s, 10, 64)
	if err != nil {
		return nil
	}
	v := uint(n)
	return &v
}

func parseUintParam(c fiber.Ctx, name string) (uint, error) {
	n, err := strconv.ParseUint(c.Params(name), 10, 64)
	if err != nil || n == 0 {
		return 0, fiber.ErrBadRequest
	}
	return uint(n), nil
}