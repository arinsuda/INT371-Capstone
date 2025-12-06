package technician

import (
	"bytes"
	"encoding/json"
	"fmt"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	tsvc "changsure-core-service/internal/modules/technician_service"
	"changsure-core-service/pkg/imageutil"
	"changsure-core-service/pkg/security"
	"changsure-core-service/pkg/storage"
	"changsure-core-service/pkg/utils"

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
		return fiber.NewError(401, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return err
	}

	res, err := h.svc.GetProfile(c.Context(), techID)
	if err != nil {
		return fiber.NewError(404, err.Error())
	}

	response := *res
	if response.AvatarURL != nil && *response.AvatarURL != "" {
		if presigned, err := storage.GlobalMinio.PresignGet(
			c.Context(), *response.AvatarURL, time.Hour, false,
		); err == nil {
			response.AvatarURL = &presigned
		}
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    response,
	})
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return err
	}

	var req TechnicianProfileReq
	contentType := c.Get(fiber.HeaderContentType)

	if strings.HasPrefix(contentType, fiber.MIMEApplicationJSON) {
		if err := c.Bind().Body(&req); err != nil {
			return fiber.NewError(400, "invalid json")
		}
	} else {

		req.FirstName = c.FormValue("firstname")
		req.LastName = c.FormValue("lastname")

		if req.FirstName == "" || req.LastName == "" {
			return fiber.NewError(400, "firstname & lastname required")
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
				return fiber.NewError(400, "invalid province_ids")
			}
		}

		if v := c.FormValue("services"); v != "" {
			if err := json.Unmarshal([]byte(v), &req.Services); err != nil {
				return fiber.NewError(400, "invalid services")
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
				return fiber.NewError(400, "image invalid")
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
				return fiber.NewError(500, "upload failed: "+err.Error())
			}

			req.AvatarURL = &key
		}
	}

	id, err := h.svc.UpsertProfile(c.Context(), techID, req)
	if err != nil {
		return fiber.NewError(400, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "message": "profile updated", "technician_id": id})
}

func (h *Handler) PatchProvinces(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return err
	}

	var req TechnicianProvincesPatchReq
	if err := c.Bind().Body(&req); err != nil || len(req.ProvinceIDs) == 0 {
		return fiber.NewError(400, "invalid province_ids")
	}

	if err := h.svc.UpdateProvinces(c.Context(), techID, req.ProvinceIDs); err != nil {
		return fiber.NewError(400, err.Error())
	}

	return c.JSON(fiber.Map{"success": true})
}

func (h *Handler) AddService(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return err
	}

	var req AddTechServiceReq
	if err := c.Bind().Body(&req); err != nil {
		return fiber.NewError(400, "invalid body")
	}

	res, err := h.svc.AddService(c.Context(), techID, req)
	if err != nil {
		return fiber.NewError(400, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) UpdateService(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return err
	}

	svcID, _ := strconv.Atoi(c.Params("id"))
	if svcID == 0 {
		return fiber.NewError(400, "invalid service id")
	}

	var req tsvc.UpdateTechServiceReq
	if err := c.Bind().Body(&req); err != nil {
		return fiber.NewError(400, "invalid body")
	}

	req.ServiceID = uint(svcID)

	res, err := h.svc.UpdateService(c.Context(), techID, req)
	if err != nil {
		return fiber.NewError(400, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "data": res})
}

func (h *Handler) RemoveService(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return err
	}

	svcID, _ := strconv.Atoi(c.Params("id"))
	if svcID == 0 {
		return fiber.NewError(400, "invalid service id")
	}

	err := h.svc.RemoveService(c.Context(), techID, RemoveTechServiceReq{ServiceID: uint(svcID)})
	if err != nil {
		return fiber.NewError(400, err.Error())
	}

	return c.JSON(fiber.Map{"success": true})
}

func (h *Handler) UploadAvatar(c fiber.Ctx) error {
	techID := utils.GetUserID(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	if err := security.CheckOwner(techID, techID); err != nil {
		return err
	}

	file, err := c.FormFile("file")
	if err != nil {
		return fiber.NewError(400, "file required")
	}

	src, _ := file.Open()
	defer src.Close()

	filename := fmt.Sprintf("%d_%d%s", techID, time.Now().Unix(), filepath.Ext(file.Filename))

	key, err := h.store.UploadFile(c.Context(), src, filename, "avatars", file.Size, file.Header.Get("Content-Type"))
	if err != nil {
		return fiber.NewError(500, "upload failed")
	}

	_ = h.svc.UpdateAvatar(c.Context(), techID, key)

	url, _ := h.store.PresignGet(c.Context(), key, time.Hour, false)

	return c.JSON(fiber.Map{"success": true, "url": url, "key": key})
}
