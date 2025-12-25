package technicianbadge

import (
	"time"

	badge "changsure-core-service/internal/modules/badge"
	"gorm.io/gorm"
)

type TechnicianBadge struct {
	ID           uint `gorm:"primaryKey;autoIncrement"`
	TechnicianID uint `gorm:"not null;index"`
	BadgeID      uint `gorm:"not null;index"`

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Badge badge.Badge `gorm:"foreignKey:BadgeID;references:ID"`
}

func (TechnicianBadge) TableName() string { return "technician_badges" }

func Models() []interface{} { return []interface{}{&TechnicianBadge{}} }
