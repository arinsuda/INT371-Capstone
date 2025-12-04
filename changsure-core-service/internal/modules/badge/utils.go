package badge

import (
	"time"

	"changsure-core-service/pkg/storage"
	"context"
	"github.com/gofiber/fiber/v3"
)

func toResponse(b *Badge) fiber.Map {
	iconURL := ""

	if b.IconURL != "" && storage.GlobalMinio != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()

		url, err := storage.GlobalMinio.PresignGet(ctx, b.IconURL, time.Hour, false)
		if err == nil {
			iconURL = url
		}
	}

	return fiber.Map{
		"id":          b.ID,
		"name":        b.Name,
		"description": b.Description,
		"icon_url":    iconURL,
		"icon_key":    b.IconURL,
		"level":       b.Level,
		"is_active":   b.IsActive,
		"created_at":  b.CreatedAt,
		"updated_at":  b.UpdatedAt,
		"deleted_at":  b.DeletedAt,
	}
}

func toResponses(badges []Badge) []fiber.Map {
	res := make([]fiber.Map, len(badges))
	for i := range badges {
		res[i] = toResponse(&badges[i])
	}
	return res
}
