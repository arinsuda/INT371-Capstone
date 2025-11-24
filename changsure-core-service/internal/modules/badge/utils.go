package badge

import (
	"github.com/gofiber/fiber/v3"
)

func toResponse(b *Badge) fiber.Map {
	return fiber.Map{
		"id":          b.ID,
		"name":        b.Name,
		"description": b.Description,
		"icon_url":    b.IconURL,
		"level":       b.Level,
		"is_active":   b.IsActive,
		"created_at":  b.CreatedAt,
		"updated_at":  b.UpdatedAt,
		"deleted_at":  b.DeletedAt,
	}
}

func toResponses(badges []Badge) []fiber.Map {
	responses := make([]fiber.Map, len(badges))
	for i, b := range badges {
		responses[i] = toResponse(&b)
	}
	return responses
}
