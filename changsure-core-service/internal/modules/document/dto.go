package document

import (
	"encoding/json"
	"time"
)

type CreateDocumentDTO struct {
	Type string `json:"type" validate:"required"`
	Slug string `json:"slug" validate:"required"`
}

type CreateVersionDTO struct {
	Locale  string          `json:"locale" validate:"required"`
	Content json.RawMessage `json:"content" validate:"required"`
}

type AcceptDTO struct {
	UserID   uint     `json:"user_id"  validate:"required,gt=0"`
	Role     string   `json:"role"     validate:"required,oneof=customer technician"`
	Consents []string `json:"consents" validate:"required,min=1"`
}

type DocumentResponse struct {
	ID   string `json:"id"`
	Type string `json:"type"`
	Slug string `json:"slug"`
}

type VersionResponse struct {
	ID          string          `json:"id"`
	DocumentID  string          `json:"document_id"`
	Version     int             `json:"version"`
	Locale      string          `json:"locale"`
	Content     json.RawMessage `json:"content"`
	IsPublished bool            `json:"is_published"`
}

type PublishedResponse struct {
	Slug      string          `json:"slug"`
	Version   int             `json:"version"`
	Locale    string          `json:"locale"`
	UpdatedAt time.Time       `json:"updated_at"`
	Content   json.RawMessage `json:"content"`
}

type AcceptanceResponse struct {
	ID         string    `json:"id"`
	UserID     uint      `json:"user_id"`
	UserRole   string    `json:"user_role"`
	DocumentID string    `json:"document_id"`
	Version    int       `json:"version"`
	AcceptedAt time.Time `json:"accepted_at"`
	Locale     string    `json:"locale"`
	Consents   []string  `json:"consents"`
}
