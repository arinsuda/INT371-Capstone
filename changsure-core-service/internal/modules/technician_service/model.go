package technicianservice

import (
	sv "changsure-core-service/internal/modules/service"
	"time"
)

type TechnicianService struct {
	ID          uint     `gorm:"primaryKey;autoIncrement" json:"id"`
	PricingType string   `gorm:"type:enum('FIXED','RANGE');not null" json:"pricing_type"`
	PriceFixed  *float64 `gorm:"type:decimal(12,2)" json:"price_fixed,omitempty"`
	PriceMin    *float64 `gorm:"type:decimal(12,2)" json:"price_min,omitempty"`
	PriceMax    *float64 `gorm:"type:decimal(12,2)" json:"price_max,omitempty"`
	IsActive    bool     `gorm:"default:true" json:"is_active"`

	CreatedAt time.Time  `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time  `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt *time.Time `gorm:"index" json:"-"`

	TechnicianID uint `gorm:"column:technician_id;not null;index" json:"technician_id"`

	ServiceID uint       `gorm:"column:service_id;not null;index" json:"service_id"`
	Service   sv.Service `gorm:"foreignKey:ServiceID;references:ID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT" json:"service"`
}

func (TechnicianService) TableName() string { return "technician_services" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianService{},
	}
}
