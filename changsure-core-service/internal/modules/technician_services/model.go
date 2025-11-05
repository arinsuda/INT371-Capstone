package technician_services

import (
	services "changsure-core-service/internal/modules/services"
	"time"
)

type TechnicianService struct {
	ID                       uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	TechnicianServiceAreasID uint       `gorm:"column:technician_service_areas_id;not null;index" json:"technician_service_areas_id"`
	ServiceID                uint       `gorm:"column:service_id;not null;index" json:"service_id"`
	PricingType              string     `gorm:"type:enum('FIXED','RANGE');not null" json:"pricing_type"`
	PriceFixed               *float64   `gorm:"type:decimal(12,2)" json:"price_fixed,omitempty"`
	PriceMin                 *float64   `gorm:"type:decimal(12,2)" json:"price_min,omitempty"`
	PriceMax                 *float64   `gorm:"type:decimal(12,2)" json:"price_max,omitempty"`
	IsActive                 bool       `gorm:"default:true" json:"is_active"`
	CreatedAt                time.Time  `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt                time.Time  `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt                *time.Time `gorm:"index" json:"-"`

	Service services.Service `gorm:"foreignKey:ID;references:ServiceID" json:"service"`
}

func (TechnicianService) TableName() string { return "technician_services" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianService{},
	}
}
