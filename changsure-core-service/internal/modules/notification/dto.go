package notification

import "time"

type CreateNotificationInput struct {
	RecipientRole RecipientRole  `json:"recipient_role" validate:"required"`
	RecipientID   uint           `json:"recipient_id"   validate:"required,gt=0"`
	Type          string         `json:"type"           validate:"required,max=64"`
	Title         string         `json:"title"          validate:"required,max=255"`
	Message       string         `json:"message"        validate:"required,max=2000"`
	EntityType    string         `json:"entity_type"    validate:"omitempty,max=32"`
	EntityID      uint           `json:"entity_id"      validate:"omitempty,gt=0"`
	Data          map[string]any `json:"data"`
}

type ListQuery struct {
	Limit      int  `query:"limit"`
	Cursor     uint `query:"cursor"`
	UnreadOnly bool `query:"unread_only"`
}

type PatchRequest struct {
	IsRead *bool `json:"is_read" validate:"required"`
}

type PatchBulkRequest struct {
	IDs    []uint `json:"ids"     validate:"required,min=1,max=100,dive,gt=0"`
	IsRead *bool  `json:"is_read" validate:"required"`
}

type NotificationResponse struct {
	ID         uint           `json:"id"`
	Type       string         `json:"type"`
	Title      string         `json:"title"`
	Message    string         `json:"message"`
	EntityType string         `json:"entity_type,omitempty"`
	EntityID   uint           `json:"entity_id,omitempty"`
	Data       map[string]any `json:"data,omitempty"`
	IsRead     bool           `json:"is_read"`
	ReadAt     *time.Time     `json:"read_at,omitempty"`
	CreatedAt  time.Time      `json:"created_at"`
}

type ListResponse struct {
	Items      []NotificationResponse `json:"items"`
	NextCursor *uint                  `json:"next_cursor"`
	HasMore    bool                   `json:"has_more"`
}

type BulkUpdateResponse struct {
	Updated int64 `json:"updated"`
}

func toResponse(n Notification) NotificationResponse {
	return NotificationResponse{
		ID:         n.ID,
		Type:       n.Type,
		Title:      n.Title,
		Message:    n.Message,
		EntityType: n.EntityType,
		EntityID:   n.EntityID,
		Data:       map[string]any(n.Data),
		IsRead:     n.IsRead,
		ReadAt:     n.ReadAt,
		CreatedAt:  n.CreatedAt,
	}
}

func toResponseList(ns []Notification) []NotificationResponse {
	out := make([]NotificationResponse, 0, len(ns))
	for _, n := range ns {
		out = append(out, toResponse(n))
	}
	return out
}
