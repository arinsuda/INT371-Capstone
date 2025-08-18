package middleware

import (
	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/compress"

	"strings"
)

func Compress() fiber.Handler {
	return compress.New(compress.Config{
		Level: compress.LevelBestSpeed, // Balance between speed and compression
		Next: func(c fiber.Ctx) bool {
			// Skip compression for certain content types
			contentType := c.Get("Content-Type")
			return strings.Contains(contentType, "image/") ||
				strings.Contains(contentType, "video/") ||
				strings.Contains(contentType, "audio/")
		},
	})
}
