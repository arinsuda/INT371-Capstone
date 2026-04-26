package technicianservicearea

import (
	"time"

	pv "changsure-core-service/internal/modules/province"
)

type TechnicianServiceArea struct {
	ID           uint        `gorm:"primaryKey;autoIncrement"`
	TechnicianID uint        `gorm:"not null;index"`
	ProvinceID   uint        `gorm:"not null;index"`
	IsActive     bool        `gorm:"default:true"`
	CreatedAt    time.Time   `gorm:"autoCreateTime"`
	UpdatedAt    time.Time   `gorm:"autoUpdateTime"`
	Province     pv.Province `gorm:"foreignKey:ProvinceID" json:"province,omitempty"`
}

func (TechnicianServiceArea) TableName() string { return "technician_service_areas" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianServiceArea{},
	}
}
