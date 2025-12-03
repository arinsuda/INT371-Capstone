package technicianwork

import (
	"time"

	pv "changsure-core-service/internal/modules/province"
	sv "changsure-core-service/internal/modules/service"

	"gorm.io/gorm"
)

type TechnicianWork struct {
	ID           uint `gorm:"primaryKey;autoIncrement" json:"id"`
	TechnicianID uint `gorm:"not null;index" json:"technician_id"`

	Title       string  `gorm:"type:varchar(150);not null" json:"title"`
	Description *string `gorm:"type:text" json:"description"`

	ServiceID  *uint      `gorm:"index" json:"service_id,omitempty"`
	ProvinceID *uint      `gorm:"index" json:"province_id,omitempty"`
	WorkDate   *time.Time `json:"work_date,omitempty"`

	IsPublished bool           `gorm:"not null;default:true" json:"is_published"`
	CreatedAt   time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index" json:"deleted_at"`

	Service  *sv.Service     `gorm:"foreignKey:ServiceID;references:ID" json:"service,omitempty"`
	Province *pv.Province   `gorm:"foreignKey:ProvinceID;references:ID" json:"province,omitempty"`
	Images   []TechnicianWorkImage `gorm:"foreignKey:WorkID" json:"images"`
}

func (TechnicianWork) TableName() string { return "technician_works" }

type TechnicianWorkImage struct {
	ID        uint           `gorm:"primaryKey;autoIncrement" json:"id"`
	WorkID    uint           `gorm:"not null;index" json:"work_id"`
	ImageURL  string         `gorm:"type:varchar(255);not null" json:"image_url"`
	SortOrder int            `gorm:"not null;default:0" json:"sort_order"`
	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"deleted_at"`
}

func (TechnicianWorkImage) TableName() string { return "technician_work_images" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianWork{},
		&TechnicianWorkImage{},
	}
}
