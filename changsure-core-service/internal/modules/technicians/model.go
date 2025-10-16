package technicians

import (
	"time"
	"gorm.io/gorm"
)

type Technician struct {
	ID          uint           `gorm:"primaryKey;autoIncrement"`
	DisplayName string         `gorm:"type:varchar(190);not null"`
	Bio         *string        `gorm:"type:text"`
	ProvinceID  *uint          `gorm:"index:idx_technicians_province"`
	Latitude    *float64       `gorm:"type:decimal(10,7);index:idx_technicians_geo,priority:1"`
	Longitude   *float64       `gorm:"type:decimal(10,7);index:idx_technicians_geo,priority:2"`
	RatingAvg   float64        `gorm:"type:decimal(3,2);not null;default:0.00"`
	RatingCount uint           `gorm:"not null;default:0"`
	IsAvailable bool           `gorm:"not null;default:true;index:idx_technicians_available"`
	CreatedAt   time.Time      `gorm:"autoCreateTime"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime"`
	DeletedAt   gorm.DeletedAt `gorm:"index"`
}

func (Technician) TableName() string { return "technicians" }

type TechnicianServiceArea struct {
	ID           uint `gorm:"primaryKey;autoIncrement"`
	TechnicianID uint `gorm:"not null;index:uq_tech_province,unique,priority:1"`
	ProvinceID   uint `gorm:"not null;index:uq_tech_province,unique,priority:2;index"`
}

func (TechnicianServiceArea) TableName() string { return "technician_service_areas" }

type PricingType string

const (
	PricingFixed      PricingType = "fixed"
	PricingRange      PricingType = "range"
	PricingNegotiable PricingType = "negotiable"
)

type TechnicianService struct {
	ID           uint        `gorm:"primaryKey;autoIncrement"`
	TechnicianID uint        `gorm:"not null;index:uq_tech_service,unique,priority:1"`
	ServiceID    uint        `gorm:"not null;index:uq_tech_service,unique,priority:2"`
	PricingType  PricingType `gorm:"type:enum('fixed','range','negotiable');not null;default:'range'"`
	PriceFixed   *float64    `gorm:"type:decimal(12,2)"`
	PriceMin     *float64    `gorm:"type:decimal(12,2);index:idx_techsvc_price_min,priority:2"`
	PriceMax     *float64    `gorm:"type:decimal(12,2)"`
	Currency     string      `gorm:"type:char(3);not null;default:'THB'"`
	IsActive     bool        `gorm:"not null;default:true;index:idx_techsvc_service_active,priority:2"`
	CreatedAt    time.Time   `gorm:"autoCreateTime"`
	UpdatedAt    time.Time   `gorm:"autoUpdateTime"`
}

func (TechnicianService) TableName() string { return "technician_services" }


func Models() []interface{} {
	return []interface{}{
		&Technician{},
		&TechnicianServiceArea{},
		&TechnicianService{},
	}
}