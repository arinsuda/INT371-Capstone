package technicianposts

import (
	"time"

	pv "changsure-core-service/internal/modules/province"
	sv "changsure-core-service/internal/modules/service"

	"gorm.io/gorm"
)

type TechnicianPost struct {
	ID           uint `gorm:"primaryKey"`
	TechnicianID uint `gorm:"not null"`

	Title       string `gorm:"size:150;not null"`
	Description *string

	ServiceID  *uint
	ProvinceID *uint
	
	IsPublished bool           `gorm:"default:true"`
	CreatedAt   time.Time      `gorm:"autoCreateTime"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime"`
	DeletedAt   gorm.DeletedAt `gorm:"index"`

	Service  *sv.Service           `gorm:"foreignKey:ServiceID"`
	Province *pv.Province          `gorm:"foreignKey:ProvinceID"`
	Images   []TechnicianPostImage `gorm:"foreignKey:PostID"`
}

func (TechnicianPost) TableName() string {
	return "technician_posts"
}

type TechnicianPostImage struct {
	ID        uint `gorm:"primaryKey"`
	PostID    uint `gorm:"not null"`
	ImageURL  string
	SortOrder int

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`
}

func (TechnicianPostImage) TableName() string {
	return "technician_post_images"
}

func Models() []interface{} {
	return []interface{}{
		&TechnicianPost{},
		&TechnicianPostImage{},
	}
}
