package technicianbadge

import (
	"context"
	"time"

	"changsure-core-service/pkg/storage"
)

func toResponse(tb *TechnicianBadge) TechnicianBadgeResponse {
	var iconURL *string

	if tb.Badge.IconURL != "" {
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()

		if url, err := storage.GlobalMinio.PresignGet(ctx, tb.Badge.IconURL, time.Hour, false); err == nil {
			iconURL = &url
		} else {
			tmp := tb.Badge.IconURL
			iconURL = &tmp
		}
	}

	return TechnicianBadgeResponse{
		ID:           tb.ID,
		TechnicianID: tb.TechnicianID,
		BadgeID:      tb.BadgeID,
		CreatedAt:    tb.CreatedAt,
		UpdatedAt:    tb.UpdatedAt,
		Badge: BadgeInfo{
			ID:          tb.Badge.ID,
			Name:        tb.Badge.Name,
			Level:       tb.Badge.Level,
			Description: &tb.Badge.Description,
			IconURL:     iconURL,
		},
	}
}

func toResponses(items []TechnicianBadge) []TechnicianBadgeResponse {
	out := make([]TechnicianBadgeResponse, len(items))
	for i := range items {
		out[i] = toResponse(&items[i])
	}
	return out
}
