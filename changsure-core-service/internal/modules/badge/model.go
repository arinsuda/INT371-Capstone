package badge

import (
	"gorm.io/gorm"
	"time"
)

type Badge struct {
	ID          uint   `gorm:"primaryKey;autoIncrement" json:"id"`
	Name        string `gorm:"type:varchar(100);not null" json:"name"`
	Description string `gorm:"type:text" json:"description"`
	IconURL     string `gorm:"type:varchar(255);not null;default:''" json:"icon_url"`
	Level       uint   `gorm:"not null" json:"level"`
	IsActive    bool   `gorm:"not null;default:true" json:"is_active"`

	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at"`
}

func (Badge) TableName() string { return "badges" }

func Models() []interface{} {
	return []interface{}{
		&Badge{},
	}
}
