package auth

import (
	"time"
)

type RefreshToken struct {
	ID        uint       `gorm:"primaryKey;autoIncrement"`
	UserID    uint       `gorm:"index;not null"`
	Role      string     `gorm:"size:20;not null"`
	Token     string     `gorm:"size:512;uniqueIndex;not null"`
	ExpiresAt time.Time  `gorm:"not null"`
	RevokedAt *time.Time `gorm:"index"`
	CreatedAt time.Time  `gorm:"autoCreateTime"`
}

func (RefreshToken) TableName() string { return "auth_refresh_tokens" }

func Models() []interface{} {
	return []interface{}{&RefreshToken{}}
}
