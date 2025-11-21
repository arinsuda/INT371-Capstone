package auth

import (
	"time"
)

type RefreshToken struct {
	ID        uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	UserID    uint       `gorm:"index;not null" json:"user_id"`
	UserRole  string     `gorm:"type:varchar(50);not null;index" json:"user_role"` 
	TokenHash string     `gorm:"type:varchar(255);not null;uniqueIndex" json:"-"`
	ExpiresAt time.Time  `gorm:"index;not null" json:"expires_at"`
	RevokedAt *time.Time `gorm:"index" json:"revoked_at,omitempty"`
	CreatedAt time.Time  `gorm:"autoCreateTime" json:"created_at"`
}

func (RefreshToken) TableName() string { return "refresh_tokens" }

func Models() []interface{} {
	return []interface{}{
		&RefreshToken{},
	}
}
