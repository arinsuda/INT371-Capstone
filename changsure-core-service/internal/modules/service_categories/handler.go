package service_categories

import (
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
		public:   true,
	}
}

func (h *Handler) List(c fiber.Ctx) error {
	items, err := h.svc.List(c.Context())
	if err != nil {
		return c.Status(500).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	return c.JSON(fiber.Map{"success": true, "data": items})
}

func (h *Handler) GetByID(c fiber.Ctx) error {
	id, err := toUint(c.Params("id"))
	if err != nil || id == 0 {
		return badRequest(c, "invalid id")
	}
	m, err := h.svc.Get(c.Context(), uint(id))
	if err != nil {
		return notFound(c, err.Error())
	}
	return c.JSON(fiber.Map{"success": true, "data": m})
}

func (h *Handler) UploadIcon(c fiber.Ctx) error {
	id64, err := toUint(c.Params("id"))
	if err != nil || id64 == 0 {
		return badRequest(c, "invalid id")
	}
	id := uint(id64)

	fh, err := c.FormFile("file")
	if err != nil {
		return badRequest(c, "file is required")
	}
	if fh.Size == 0 {
		return badRequest(c, "empty file")
	}

	file, err := fh.Open()
	if err != nil {
		return badRequest(c, err.Error())
	}
	defer file.Close()

	mime := sniffMIME(file)
	if _, ok := allowedMIME[mime]; !ok {
		return badRequest(c, "only image/jpeg,image/png,image/webp")
	}
	if _, err := file.(multipart.File).Seek(0, io.SeekStart); err != nil {
		return badRequest(c, "failed to rewind file")
	}

	ext := strings.ToLower(filepath.Ext(fh.Filename))
	if ext == "" {
		ext = guessExt(mime)
	}

	key := fmt.Sprintf("service-categories/%d/icon-%d%s", id, time.Now().Unix(), ext)
	if _, err := h.storage.Put(c.Context(), key, file, fh.Size, mime); err != nil {
		return c.Status(http.StatusInternalServerError).JSON(fiber.Map{"success": false, "error": err.Error()})
	}

	var url string
	if h.public {
		url = h.storage.PublicURL(key)
	} else {
		u, err := h.storage.PresignGet(c.Context(), key, 10*time.Minute, false)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{"success": false, "error": err.Error()})
		}
		url = u
	}

	if err := h.svc.UpdateImageURL(c.Context(), id, url); err != nil {
		return c.Status(500).JSON(fiber.Map{"success": false, "error": err.Error()})
	}
	return c.Status(http.StatusCreated).JSON(fiber.Map{"success": true, "data": fiber.Map{"icon_url": url}})
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

func badRequest(c fiber.Ctx, msg string) error {
	return c.Status(http.StatusBadRequest).JSON(fiber.Map{"success": false, "error": msg})
}
func notFound(c fiber.Ctx, msg string) error {
	return c.Status(http.StatusNotFound).JSON(fiber.Map{"success": false, "error": msg})
}
