package document

import (
	"crypto/sha256"
	"encoding/hex"
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type Document struct {
	ID        uuid.UUID `gorm:"type:char(36);primaryKey"`
	Type      string    `gorm:"size:50;index;not null"`
	Slug      string    `gorm:"size:120;uniqueIndex;not null"`
	CreatedAt time.Time
	UpdatedAt time.Time

	Versions []DocumentVersion `gorm:"foreignKey:DocumentID"`
}

func (d *Document) BeforeCreate(tx *gorm.DB) error {
	d.ID = uuid.New()
	return nil
}

func (v *DocumentVersion) BeforeCreate(tx *gorm.DB) error {
	v.ID = uuid.New()
	v.Checksum = hashJSON(v.Content)
	return nil
}

type DocumentVersion struct {
	ID          uuid.UUID      `gorm:"type:char(36);primaryKey"`
	DocumentID  uuid.UUID      `gorm:"type:char(36);index"`
	Version     int            `gorm:"index"`
	Locale      string         `gorm:"size:10;index"`
	Content     datatypes.JSON `gorm:"type:json"`
	Checksum    string         `gorm:"size:64;index"`
	IsPublished bool
	PublishedAt *time.Time
	CreatedAt   time.Time
}

func hashJSON(j datatypes.JSON) string {
	h := sha256.Sum256(j)
	return hex.EncodeToString(h[:])
}

type DocumentAcceptance struct {
	ID         uuid.UUID `gorm:"type:char(36);primaryKey"`
	UserID     uint      `gorm:"index"`
	UserRole   string    `gorm:"size:20;index"`
	DocumentID uuid.UUID `gorm:"type:char(36);index"`
	Version    int
	AcceptedAt time.Time
}

func Models() []interface{} {
	return []interface{}{&Document{}, &DocumentVersion{}, &DocumentAcceptance{}}
}
