package services

import (
	"time"
	"changsure-core-service/internal/modules/service_categories"
)

type Service struct {
	ID              uint      `gorm:"primaryKey;autoIncrement"`
	Name            string    `gorm:"type:varchar(190);not null"`
	Description     *string   `gorm:"type:text"`
	IconURL         *string   `gorm:"type:varchar(500)"`
	DurationMinutes *int      `gorm:"type:int"`
	IsActive        bool      `gorm:"not null;default:true;index:idx_services_category_active,priority:2"`
	CreatedAt       time.Time `gorm:"autoCreateTime"`
	UpdatedAt       time.Time `gorm:"autoUpdateTime"`

	CategoryID uint                                 `gorm:"index:idx_services_category_active,priority:1;not null" json:"category_id"`
	Category   *service_categories.ServiceCategory `gorm:"foreignKey:CategoryID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"category,omitempty"`
}

func (Service) TableName() string { return "services" }

func Models() []interface{} {
	return []interface{}{
		&Service{},
	}
}