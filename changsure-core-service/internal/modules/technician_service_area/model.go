package technicianservicearea

import (
	"time"

	pv "changsure-core-service/internal/modules/province"
)

type TechnicianServiceArea struct {
	ID           uint
	TechnicianID uint
	ProvinceID   uint
	IsActive     bool
	CreatedAt    time.Time
	UpdatedAt    time.Time

	Province pv.Province `gorm:"foreignKey:ProvinceID" json:"province,omitempty"`
}

func (TechnicianServiceArea) TableName() string { return "technician_service_areas" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianServiceArea{},
	}
}
