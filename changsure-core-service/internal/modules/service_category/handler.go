package servicecategory

import (
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gofiber/fiber/v3"

	"changsure-core-service/internal/config"
	"changsure-core-service/pkg/storage"

	apperrors "changsure-core-service/internal/errors"
)

type Handler struct {
	svc      Service
	storage  *storage.MinioStorage
	endpoint string
	bucket   string
	public   bool
}

func NewHandler(s Service, st *storage.MinioStorage, cfg *config.Config) *Handler {
	return &Handler{
		svc:      s,
		storage:  st,
		endpoint: cfg.Minio.PublicBaseURL,
		bucket:   cfg.Minio.Bucket,
		public:   false,
	}
}

func (h *Handler) ListServiceCategories(c fiber.Ctx) error {
	items, err := h.svc.ListServiceCategories(c.Context())
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	resp := make([]CategoryResponse, 0, len(items))
	for _, it := range items {
		resp = append(resp, MapCategoryToResponse(&it))
	}

	return c.JSON(fiber.Map{"success": true, "data": resp})
}

func (h *Handler) GetServiceCategoryById(c fiber.Ctx) error {
	id, err := toUint(c.Params("id"))
	if err != nil || id == 0 {
		return apperrors.BadRequest(c, "invalid id")
	}

	m, err := h.svc.GetServiceCategoryById(c.Context(), uint(id))
	if err != nil {
		return apperrors.NotFound(c, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "data": MapCategoryToResponse(m)})
}

func (h *Handler) CreateServiceCategory(c fiber.Ctx) error {
	var body struct {
		CatName string  `form:"cat_name"`
		CatDesc *string `form:"cat_desc"`
	}

	if err := c.Bind().Body(&body); err != nil {
		return apperrors.BadRequest(c, "invalid request body")
	}
	if body.CatName == "" {
		return apperrors.BadRequest(c, "cat_name is required")
	}

	m := &ServiceCategory{
		CatName:  body.CatName,
		CatDesc:  body.CatDesc,
		IsActive: true,
	}

	if err := h.svc.CreateServiceCategory(c.Context(), m); err != nil {
		return c.Status(500).JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	return c.Status(201).JSON(fiber.Map{"success": true, "data": MapCategoryToResponse(m)})
}

func (h *Handler) UpdateServiceCategory(c fiber.Ctx) error {
	id64, err := toUint(c.Params("id"))
	if err != nil || id64 == 0 {
		return apperrors.BadRequest(c, "invalid id")
	}
	id := uint(id64)

	var body struct {
		CatName  *string `form:"cat_name"`
		CatDesc  *string `form:"cat_desc"`
		IsActive *bool   `form:"is_active"`
	}

	if err := c.Bind().Body(&body); err != nil {
		return apperrors.BadRequest(c, "invalid request body")
	}

	fields := map[string]any{}

	if body.CatName != nil && *body.CatName != "" {
		fields["cat_name"] = *body.CatName
	}

	if body.CatDesc != nil && *body.CatDesc != "" {
		fields["cat_description"] = *body.CatDesc
	}
	if body.IsActive != nil {
		fields["is_active"] = *body.IsActive
	}

	fileHeader, err := c.FormFile("icon_url")
	if err == nil && fileHeader != nil {
		file, err := fileHeader.Open()
		if err != nil {
			return apperrors.BadRequest(c, "cannot open icon file")
		}
		defer file.Close()

		mime := sniffMIME(file)
		if _, ok := allowedMIME[mime]; !ok {
			return apperrors.BadRequest(c, "only jpg/png/webp allowed")
		}

		file.(multipart.File).Seek(0, io.SeekStart)

		ext := strings.ToLower(filepath.Ext(fileHeader.Filename))
		if ext == "" {
			ext = guessExt(mime)
		}

		key := fmt.Sprintf("service-categories/%d/icon-%d%s",
			id, time.Now().Unix(), ext)

		_, err = h.storage.Put(c.Context(), key, file, fileHeader.Size, mime)
		if err != nil {
			return apperrors.InternalServerError(c, "icon upload failed")
		}

		fields["icon_url"] = key
	}

	if len(fields) == 0 {
		return apperrors.BadRequest(c, "no fields to update")
	}

	if err := h.svc.UpdateFields(c.Context(), id, fields); err != nil {
		if errors.Is(err, ErrServiceCategoryNotFound) {
			return apperrors.NotFound(c, "service category not found")
		}
		return apperrors.InternalServerError(c, err.Error())
	}

	m, err := h.svc.GetServiceCategoryById(c.Context(), id)
	if err != nil {
		return apperrors.NotFound(c, "service category not found")
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    MapCategoryToResponse(m),
	})
}

func (h *Handler) DeleteServiceCategoryById(c fiber.Ctx) error {
	id64, err := toUint(c.Params("id"))
	if err != nil || id64 == 0 {
		return apperrors.BadRequest(c, "invalid id")
	}
	id := uint(id64)

	fields := map[string]any{"is_active": false}

	if err := h.svc.UpdateFields(c.Context(), id, fields); err != nil {
		if errors.Is(err, ErrServiceCategoryNotFound) {
			return apperrors.NotFound(c, "service category not found")
		}
		return apperrors.InternalServerError(c, err.Error())
	}

	return c.JSON(fiber.Map{"success": true, "message": "service category deleted"})
}

func (h *Handler) UploadIconServiceCategory(c fiber.Ctx) error {
	id64, err := toUint(c.Params("id"))
	if err != nil || id64 == 0 {
		return apperrors.BadRequest(c, "invalid id")
	}
	id := uint(id64)

	fh, err := c.FormFile("file")
	if err != nil {
		return apperrors.BadRequest(c, "file is required")
	}
	if fh.Size == 0 {
		return apperrors.BadRequest(c, "empty file")
	}

	file, err := fh.Open()
	if err != nil {
		return apperrors.BadRequest(c, err.Error())
	}
	defer file.Close()

	mime := sniffMIME(file)
	if _, ok := allowedMIME[mime]; !ok {
		return apperrors.BadRequest(c, "only image/jpeg,image/png,image/webp")
	}

	if _, err := file.(multipart.File).Seek(0, io.SeekStart); err != nil {
		return apperrors.BadRequest(c, "failed to rewind file")
	}

	ext := strings.ToLower(filepath.Ext(fh.Filename))
	if ext == "" {
		ext = guessExt(mime)
	}

	key := fmt.Sprintf("service-categories/%d/icon-%d%s", id, time.Now().Unix(), ext)

	_, err = h.storage.Put(c.Context(), key, file, fh.Size, mime)
	if err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	if err := h.svc.UpdateImageURL(c.Context(), id, key); err != nil {
		return c.Status(500).JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	presignedURL, err := h.storage.PresignGet(c.Context(), key, 1*time.Hour, false)
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	return c.Status(http.StatusCreated).JSON(fiber.Map{
		"success": true,
		"data": fiber.Map{
			"icon_url": presignedURL,
		},
	})
}

var allowedMIME = map[string]struct{}{
	"image/jpeg": {}, "image/png": {}, "image/webp": {},
}

func sniffMIME(r io.Reader) string {
	buf := make([]byte, 512)
	n, _ := io.ReadFull(r, buf)
	return http.DetectContentType(buf[:n])
}

func guessExt(m string) string {
	switch m {
	case "image/jpeg":
		return ".jpg"
	case "image/png":
		return ".png"
	case "image/webp":
		return ".webp"
	default:
		return ".bin"
	}
}

func toUint(s string) (uint64, error) { return strconv.ParseUint(s, 10, 64) }
