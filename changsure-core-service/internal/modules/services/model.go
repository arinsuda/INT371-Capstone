package services

import (
	"changsure-core-service/internal/modules/service_categories"
	"time"
)

type Service struct {
	ID             uint      `gorm:"primaryKey;autoIncrement"`
	SerName        string    `gorm:"column:ser_name;type:varchar(190);not null"`
	SerDescription *string   `gorm:"column:ser_description;type:text"`
	ImageURL       *string   `gorm:"type:varchar(500)"`
	IsActive       bool      `gorm:"column:is_active;not null;default:true;index:idx_services_category_active,priority:2"`
	CreatedAt      time.Time `gorm:"autoCreateTime"`
	UpdatedAt      time.Time `gorm:"autoUpdateTime"`

	CategoryID uint                                `gorm:"column:category_id;not null;index:idx_services_category_active,priority:1" json:"category_id"`
	Category   *service_categories.ServiceCategory `gorm:"foreignKey:CategoryID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"category,omitempty"`
}

func (Service) TableName() string { return "services" }

func Models() []interface{} {
	return []interface{}{
		&Service{},
	}
}
