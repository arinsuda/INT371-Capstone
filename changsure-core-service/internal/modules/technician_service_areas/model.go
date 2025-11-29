package technician_service_areas

import (
	"time"

	provinces "changsure-core-service/internal/modules/provinces"
)

type TechnicianServiceArea struct {
	ID           uint
	TechnicianID uint
	ProvinceID   uint
	IsActive     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time

	Province provinces.Province `gorm:"foreignKey:ProvinceID" json:"province,omitempty"`
}

func (TechnicianServiceArea) TableName() string { return "technician_service_areas" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianServiceArea{},
	}
}
