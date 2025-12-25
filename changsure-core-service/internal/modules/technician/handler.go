package technician

import (
	"bytes"
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	tsvc "changsure-core-service/internal/modules/technician_service"
	"changsure-core-service/pkg/imageutil"
	"changsure-core-service/pkg/security"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

	appErrors "changsure-core-service/internal/errors"

	"github.com/gofiber/fiber/v3"
)

type Handler struct {
	svc   Service
	store *storage.MinioStorage
}

func NewHandler(s Service, store *storage.MinioStorage) *Handler {
	return &Handler{
		svc:   s,
		store: store,
	}
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return appErrors.Forbidden(c, err.Error())
	}

	res, err := h.svc.GetProfile(c.Context(), techID)
	if err != nil {
		return appErrors.NotFound(c, err.Error())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    res,
	})
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return appErrors.Forbidden(c, err.Error())
	}

	var req TechnicianProfileReq
	contentType := c.Get(fiber.HeaderContentType)

	if strings.HasPrefix(contentType, fiber.MIMEApplicationJSON) {
		if err := c.Bind().Body(&req); err != nil {
			return appErrors.BadRequest(c, "invalid json")
		}
	} else {

		req.FirstName = c.FormValue("firstname")
		req.LastName = c.FormValue("lastname")

		if req.FirstName == "" || req.LastName == "" {
			return appErrors.BadRequest(c, "firstname & lastname required")
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

		if v := c.FormValue("province_ids"); v != "" {
			if err := json.Unmarshal([]byte(v), &req.ProvinceIDs); err != nil {
				return appErrors.BadRequest(c, "invalid province_ids")
			}
		}

		if v := c.FormValue("services"); v != "" {
			if err := json.Unmarshal([]byte(v), &req.Services); err != nil {
				return appErrors.BadRequest(c, "invalid services")
			}
		}

		fileHeader, err := c.FormFile("avatar")
		if err == nil {
			file, _ := fileHeader.Open()
			defer file.Close()

			var raw bytes.Buffer
			raw.ReadFrom(file)

			opt := imageutil.ResizeOptions{
				MaxWidth:    800,
				MaxFileSize: 500000,
				Quality:     85,
			}

			imgBuf, err := imageutil.OptimizeImage(bytes.NewReader(raw.Bytes()), opt)
			if err != nil {
				return appErrors.BadRequest(c, "image invalid")
			}

			filename := fmt.Sprintf("%d_%d.jpg", techID, time.Now().Unix())

			key, err := h.store.UploadFile(
				c.Context(),
				bytes.NewReader(imgBuf.Bytes()),
				filename,
				"avatars",
				int64(imgBuf.Len()),
				"image/jpeg",
			)
			if err != nil {
				return appErrors.InternalError(c, "upload failed", err)
			}

			req.AvatarURL = &key
		}
	}

	id, err := h.svc.UpsertProfile(c.Context(), techID, req)
	if err != nil {
		return appErrors.InternalError(c, "failed to update profile", err)
	}

	return c.JSON(fiber.Map{"success": true, "message": "profile updated", "technician_id": id})
}

func (h *Handler) PatchProvinces(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return appErrors.Forbidden(c, err.Error())
	}

	var req TechnicianProvincesPatchReq
	if err := c.Bind().Body(&req); err != nil || len(req.ProvinceIDs) == 0 {
		return appErrors.BadRequest(c, "invalid province_ids")
	}

	if err := h.svc.UpdateProvinces(c.Context(), techID, req.ProvinceIDs); err != nil {
		return appErrors.InternalError(c, "failed to update provinces", err)
	}

	return c.JSON(fiber.Map{"success": true})
}

func (h *Handler) AddService(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return appErrors.Forbidden(c, err.Error())
	}

	var req AddTechServiceReq
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid body")
	}

	res, err := h.svc.AddService(c.Context(), techID, req)
	if err != nil {
		return appErrors.InternalError(c, "failed to add service", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) UpdateService(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return appErrors.Forbidden(c, err.Error())
	}

	svcID, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid service id")
	}

	var req tsvc.UpdateTechServiceReq
	if err := c.Bind().Body(&req); err != nil {
		return appErrors.BadRequest(c, "invalid body")
	}

	req.ServiceID = svcID

	res, err := h.svc.UpdateService(c.Context(), techID, req)
	if err != nil {
		return appErrors.InternalError(c, "failed to update service", err)
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) RemoveService(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return appErrors.Forbidden(c, err.Error())
	}

	svcID, err := utils.ParseUintParam(c, "id")
	if err != nil {
		return appErrors.BadRequest(c, "invalid service id")
	}

	err = h.svc.RemoveService(c.Context(), techID, RemoveTechServiceReq{ServiceID: svcID})
	if err != nil {
		return appErrors.InternalError(c, "failed to remove service", err)
	}

	return c.JSON(fiber.Map{"success": true})
}

func (h *Handler) UploadAvatar(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return appErrors.Unauthorized(c, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return appErrors.Forbidden(c, err.Error())
	}

	file, err := c.FormFile("file")
	if err != nil {
		return appErrors.BadRequest(c, "file required")
	}

	src, _ := file.Open()
	defer src.Close()

	filename := fmt.Sprintf("%d_%d%s", techID, time.Now().Unix(), filepath.Ext(file.Filename))

	key, err := h.store.UploadFile(c.Context(), src, filename, "avatars", file.Size, file.Header.Get("Content-Type"))
	if err != nil {
		return appErrors.InternalError(c, "upload failed", err)
	}

	_ = h.svc.UpdateAvatar(c.Context(), techID, key)

	url, _ := h.store.PresignGet(c.Context(), key, time.Hour, false)

	return c.JSON(fiber.Map{"success": true, "url": url, "key": key})
}
