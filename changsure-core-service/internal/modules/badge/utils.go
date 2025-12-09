package badge

import (
	"context"
	"strings"
	"time"

	"changsure-core-service/pkg/storage"
)

func normalizeKey(key string) string {
	if strings.HasPrefix(key, "http://") || strings.HasPrefix(key, "https://") {
		return ""
	}
	return strings.TrimLeft(key, "/")
}

func generatePresigned(store *storage.MinioStorage, key string) string {
	if store == nil || key == "" {
		return ""
	}

	key = normalizeKey(key)

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	url, err := store.PresignGet(ctx, key, time.Hour, false)
	if err != nil {
		return ""
	}
	return url
}

func toResponse(b *Badge, store *storage.MinioStorage) BadgeResponse {
	return BadgeResponse{
		ID:          b.ID,
		Name:        b.Name,
		Description: b.Description,
		IconURL:     generatePresigned(store, b.IconURL),
		Level:       b.Level,
		IsActive:    b.IsActive,
		CreatedAt:   b.CreatedAt.Unix(),
		UpdatedAt:   b.UpdatedAt.Unix(),
	}
}

func toResponses(items []Badge, store *storage.MinioStorage) []BadgeResponse {
	res := make([]BadgeResponse, 0, len(items))
	for i := range items {
		res = append(res, toResponse(&items[i], store))
	}
	return res
}

func normalizeIconKey(icon string) string {
	if icon == "" {
		return ""
	}
	if strings.HasPrefix(icon, "http://") || strings.HasPrefix(icon, "https://") {
		return ""
	}
	return strings.TrimLeft(icon, "/")
}
