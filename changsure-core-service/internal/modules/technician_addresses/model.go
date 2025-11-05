package technician_addresses

import (
	"time"

	provinces "changsure-core-service/internal/modules/provinces"
	tech_services "changsure-core-service/internal/modules/technician_services"
)

type TechnicianServiceArea struct {
	ID           uint
	TechnicianID uint
	ProvinceID   uint
	IsActive     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time

	Province provinces.Province           `gorm:"foreignKey:ProvinceID" json:"province,omitempty"`
	Services []tech_services.TechnicianService `gorm:"foreignKey:TechnicianServiceAreasID" json:"services,omitempty"`
}

func (TechnicianServiceArea) TableName() string { return "technician_service_areas" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianServiceArea{},
	}
}
