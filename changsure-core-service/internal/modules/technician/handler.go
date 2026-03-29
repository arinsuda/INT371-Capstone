package technician

import (
	"bytes"
	"encoding/json"
	"fmt"
	"mime/multipart"
	"strconv"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/middleware"
	"changsure-core-service/pkg/imageutil"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc   Service
	store storage.Storage
}

func NewHandler(s Service, store storage.Storage) *Handler {
	return &Handler{svc: s, store: store}
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	res, err := h.svc.GetProfile(c.Context(), techID)
	if err != nil {
		return appErrors.NotFound(c, "technician not found")
	}
	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	req, err := h.bindProfileReq(c, techID)
	if err != nil {
		return appErrors.BadRequest(c, err.Error())
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	id, err := h.svc.UpsertProfile(ctx, techID, req)
	if err != nil {
		return appErrors.InternalError(c, "failed to update profile", err)
	}

	profile, err := h.svc.GetProfile(ctx, id)
	if err != nil {
		return appErrors.InternalError(c, "failed to fetch updated profile", err)
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    profile,
	})
}

func (h *Handler) UploadAvatar(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	fileHeader, err := c.FormFile("file")
	if err != nil {
		return appErrors.BadRequest(c, "file is required")
	}

	key, err := h.processAndUploadAvatar(c, techID, fileHeader)
	if err != nil {
		return appErrors.InternalError(c, "upload avatar failed", err)
	}

	if err := h.svc.UpdateAvatar(c.Context(), techID, key); err != nil {
		return appErrors.InternalError(c, "failed to update avatar record", err)
	}

	profile, err := h.svc.GetProfile(c.Context(), techID)
	if err != nil {
		return appErrors.InternalError(c, "failed to fetch updated profile", err)
	}

	url, _ := h.store.PresignGet(c.Context(), key, time.Hour, false)
	return c.JSON(fiber.Map{"success": true, "data": fiber.Map{"url": url, "profile": profile}})
}

func (h *Handler) PatchProvinces(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var req TechnicianProvincesPatchReq
	if err := c.Bind().Body(&req); err != nil || len(req.ProvinceIDs) == 0 {
		return appErrors.BadRequest(c, "province_ids is required")
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	if err := h.svc.UpdateProvinces(ctx, techID, req.ProvinceIDs); err != nil {
		return appErrors.InternalError(c, "failed to update provinces", err)
	}

	profile, err := h.svc.GetProfile(ctx, techID)
	if err != nil {
		return appErrors.InternalError(c, "failed to fetch updated profile", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": profile})
}

func (h *Handler) AddService(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	var req AddTechServiceReq
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	res, err := h.svc.AddService(ctx, techID, req)
	if err != nil {
		return appErrors.InternalError(c, "failed to add service", err)
	}
	return c.Status(fiber.StatusCreated).JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) UpdateService(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	serviceID, err := utils.ParseUintParam(c, "serviceID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid service id")
	}

	var req UpdateTechServiceReq
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid request body")
	}
	req.ServiceID = serviceID

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	res, err := h.svc.UpdateService(ctx, techID, req)
	if err != nil {
		return appErrors.HandleError(c, err)
	}
	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) RemoveService(c fiber.Ctx) error {
	techID, err := utils.ParseUintParam(c, "technicianID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid technician id")
	}

	if err := middleware.CheckOwnerOrAdmin(c, techID); err != nil {
		return appErrors.HandleError(c, err)
	}

	serviceID, err := utils.ParseUintParam(c, "serviceID")
	if err != nil {
		return appErrors.BadRequest(c, "invalid service id")
	}

	callerID, _ := middleware.GetUserID(c)
	ctx := utils.InjectUserIDIntoContext(c.Context(), callerID)

	if err := h.svc.RemoveService(ctx, techID, RemoveTechServiceReq{ServiceID: serviceID}); err != nil {
		return appErrors.HandleError(c, err)
	}

	return c.JSON(fiber.Map{"success": true})
}

func (h *Handler) ListTechnicians(c fiber.Ctx) error {
	if err := middleware.CheckAdmin(c); err != nil {
		return err
	}
	page, pageSize := parsePagination(c)

	list, total, stats, err := h.svc.List(c.Context(), page, pageSize)
	if err != nil {
		return appErrors.InternalError(c, "failed to list technicians", err)
	}

	totalPages := int((total + int64(pageSize) - 1) / int64(pageSize))

	return c.JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"technicians":    list,
			"page":           page,
			"page_size":      pageSize,
			"total":          total,
			"total_pages":    totalPages,
			"verified_count": stats.VerifiedCount,
			"pending_count":  stats.PendingCount,
		},
	})
}

func (h *Handler) bindProfileReq(c fiber.Ctx, techID uint) (TechnicianProfileReq, error) {
	var req TechnicianProfileReq

	if c.Is("json") {
		if err := c.Bind().Body(&req); err != nil {
			return req, fmt.Errorf("invalid JSON body")
		}
		return req, nil
	}

	req.FirstName = c.FormValue("firstname")
	req.LastName = c.FormValue("lastname")
	if req.FirstName == "" || req.LastName == "" {
		return req, fmt.Errorf("firstname and lastname are required")
	}
	if v := c.FormValue("bio"); v != "" {
		req.Bio = &v
	}
	if v := c.FormValue("phone"); v != "" {
		req.Phone = &v
	}
	if v := c.FormValue("email"); v != "" {
		req.Email = &v
	}

	if fileHeader, err := c.FormFile("avatar"); err == nil {
		key, uploadErr := h.processAndUploadAvatar(c, techID, fileHeader)
		if uploadErr != nil {
			return req, fmt.Errorf("avatar upload failed")
		}
		req.AvatarURL = &key
	}

	if v := c.FormValue("province_ids"); v != "" {
		if err := json.Unmarshal([]byte(v), &req.ProvinceIDs); err != nil {
			return req, fmt.Errorf("invalid province_ids format")
		}
	}

	if v := c.FormValue("services"); v != "" {
		if err := json.Unmarshal([]byte(v), &req.Services); err != nil {
			return req, fmt.Errorf("invalid services format")
		}
	}

	return req, nil
}

func (h *Handler) processAndUploadAvatar(c fiber.Ctx, techID uint, fh *multipart.FileHeader) (string, error) {
	src, err := fh.Open()
	if err != nil {
		return "", appErrors.BadRequest(c, "failed to open avatar file")
	}
	defer src.Close()

	var raw bytes.Buffer
	if _, err := raw.ReadFrom(src); err != nil {
		return "", appErrors.BadRequest(c, "failed to read avatar file")
	}

	optimized, err := imageutil.OptimizeImage(bytes.NewReader(raw.Bytes()), imageutil.ResizeOptions{
		MaxWidth:    800,
		MaxFileSize: 500_000,
		Quality:     85,
	})
	if err != nil {
		return "", appErrors.BadRequest(c, "invalid image format")
	}

	filename := fmt.Sprintf("%d_%d.jpg", techID, time.Now().Unix())
	key, err := h.store.UploadFile(
		c.Context(),
		bytes.NewReader(optimized.Bytes()),
		filename, "avatars",
		int64(optimized.Len()),
		"image/jpeg",
	)
	if err != nil {
		return "", appErrors.InternalError(c, "failed to upload avatar", err)
	}
	return key, nil
}

func parsePagination(c fiber.Ctx) (page, pageSize int) {
	page, pageSize = 1, 10
	if p, err := strconv.Atoi(c.Query("page")); err == nil && p > 0 {
		page = p
	}
	if s, err := strconv.Atoi(c.Query("page_size")); err == nil && s > 0 {
		pageSize = s
	}
	return
}
