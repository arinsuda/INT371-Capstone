package technicianbadge

import (
	"time"

	"gorm.io/gorm"
	badge "changsure-core-service/internal/modules/badge"
)

type TechnicianBadge struct {
	ID           uint `gorm:"primaryKey;autoIncrement" json:"id"`
	TechnicianID uint `gorm:"not null;index" json:"technician_id"`
	BadgeID      uint `gorm:"not null;index" json:"badge_id"`

	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	Badge badge.Badge `gorm:"foreignKey:BadgeID;references:ID" json:"badge"`
}

func (TechnicianBadge) TableName() string { return "technician_badges" }

func Models() []interface{} {
	return []interface{}{&TechnicianBadge{}}
}
