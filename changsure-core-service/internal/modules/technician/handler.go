package technician

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	tsvc "changsure-core-service/internal/modules/technician_service"
	"changsure-core-service/pkg/imageutil"
	"changsure-core-service/pkg/storage"

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

func techIDFromLocals(c fiber.Ctx) uint {
	if v := c.Locals("tech_id"); v != nil {
		switch x := v.(type) {
		case uint:
			return x
		case uint64:
			return uint(x)
		case int:
			return uint(x)
		case string:
			id, _ := strconv.ParseUint(x, 10, 64)
			return uint(id)
		}
	}

	if v := c.Locals("userID"); v != nil {
		switch x := v.(type) {
		case uint:
			return x
		case uint64:
			return uint(x)
		case int:
			return uint(x)
		case string:
			id, _ := strconv.ParseUint(x, 10, 64)
			return uint(id)
		}
	}

	return 0
}

func (h *Handler) UpdateProfile(c fiber.Ctx) error {
	var req TechnicianProfileReq

	techID := techIDFromLocals(c)
	if techID == 0 {
		return c.Status(401).JSON(fiber.Map{"success": false, "error": "unauthorized"})
	}

	contentType := c.Get(fiber.HeaderContentType)

	if strings.HasPrefix(contentType, fiber.MIMEApplicationJSON) {
		if err := c.Bind().Body(&req); err != nil {
			return c.Status(400).JSON(fiber.Map{"success": false, "error": "invalid json: " + err.Error()})
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
			file, err := fileHeader.Open()
			if err != nil {
				return fiber.NewError(500, "failed to open file")
			}
			defer file.Close()

			var raw bytes.Buffer
			raw.ReadFrom(file)

			opt := imageutil.ResizeOptions{
				MaxWidth:    800,
				MaxFileSize: 500_000,
				Quality:     85,
			}

			imgBuf, err := imageutil.OptimizeImage(bytes.NewReader(raw.Bytes()), opt)
			if err != nil {
				return fiber.NewError(400, "image invalid or too large")
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

	return c.JSON(fiber.Map{"success": true, "message": "profile updated", "data": fiber.Map{"technician_id": id}})
}

func (h *Handler) GetProfile(c fiber.Ctx) error {
    techID := techIDFromLocals(c)
    if techID == 0 {
        return c.Status(401).JSON(fiber.Map{"success": false, "error": "unauthorized"})
    }

    res, err := h.svc.GetProfile(c.Context(), techID)
    if err != nil {
        return c.Status(404).JSON(fiber.Map{"success": false, "error": err.Error()})
    }
	

    response := *res

    if response.AvatarURL != nil && *response.AvatarURL != "" {
        objectKey := *response.AvatarURL 

        presigned, err := storage.GlobalMinio.PresignGet(
            c.Context(),
            objectKey,
            time.Hour,
            false,
        )

        if err == nil {
            response.AvatarURL = &presigned
        }
    }

    return c.JSON(fiber.Map{
        "success": true,
        "data":    response,
    })
}


func (h *Handler) AddService(c fiber.Ctx) error {
	techID := techIDFromLocals(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	var body AddTechServiceReq
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(400, "invalid body")
	}

	result, err := h.svc.AddService(c.Context(), techID, body)
	if err != nil {
		return fiber.NewError(400, err.Error())
	}

	return c.Status(201).JSON(fiber.Map{
		"success": true,
		"message": "service added",
		"data":    result,
	})
}

func (h *Handler) RemoveService(c fiber.Ctx) error {
	techID := techIDFromLocals(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	serviceID, _ := strconv.Atoi(c.Params("id"))
	if serviceID == 0 {
		return fiber.NewError(400, "invalid service id")
	}

	body := RemoveTechServiceReq{ServiceID: uint(serviceID)}

	if err := h.svc.RemoveService(c.Context(), techID, body); err != nil {
		return fiber.NewError(400, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "message": "service removed"})
}

func (h *Handler) UpdateService(c fiber.Ctx) error {
	techID := techIDFromLocals(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	serviceID, _ := strconv.Atoi(c.Params("id"))
	if serviceID == 0 {
		return fiber.NewError(400, "invalid service id")
	}

	var body tsvc.UpdateTechServiceReq
	if err := c.Bind().Body(&body); err != nil {
		return fiber.NewError(400, "invalid body")
	}

	body.ServiceID = uint(serviceID)

	result, err := h.svc.UpdateService(c.Context(), techID, body)
	if err != nil {
		return fiber.NewError(400, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "message": "service updated", "data": result})
}

func (h *Handler) UploadAvatar(c fiber.Ctx) error {
	techID := techIDFromLocals(c)
	if techID == 0 {
		return fiber.NewError(401, "unauthorized")
	}

	file, err := c.FormFile("file")
	if err != nil {
		return fiber.NewError(400, "file is required")
	}

	src, err := file.Open()
	if err != nil {
		return fiber.NewError(500, "cannot open file")
	}
	defer src.Close()

	ext := filepath.Ext(file.Filename)
	if ext == "" {
		ext = ".jpg"
	}

	filename := fmt.Sprintf("%d_%d%s", techID, time.Now().Unix(), ext)

	key, err := h.store.UploadFile(
		c.Context(),
		src,
		filename,
		"avatars",
		file.Size,
		file.Header.Get("Content-Type"),
	)
	if err != nil {
		return fiber.NewError(500, "upload failed")
	}

	if err := h.svc.UpdateAvatar(c.Context(), techID, key); err != nil {
		return fiber.NewError(500, "db update failed")
	}

	url, _ := h.store.PresignGet(c.Context(), key, time.Hour, false)

	return c.JSON(fiber.Map{"success": true, "url": url, "key": key})
}

func (h *Handler) PatchProvinces(c fiber.Ctx) error {
	var req TechnicianProvincesPatchReq

	if err := c.Bind().Body(&req); err != nil || len(req.ProvinceIDs) == 0 {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   "invalid body: province_ids required",
		})
	}

	techID := techIDFromLocals(c)
	if techID == 0 {
		return c.Status(http.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"error":   "unauthorized",
		})
	}

	if err := h.svc.UpdateProvinces(c.Context(), techID, req.ProvinceIDs); err != nil {
		return c.Status(http.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"error":   err.Error(),
		})
	}
	return c.JSON(fiber.Map{"success": true})
}
