package technicianposts

import (
	"time"

	"changsure-core-service/internal/modules/admin"
	pv "changsure-core-service/internal/modules/province"
	sv "changsure-core-service/internal/modules/service"
	sc "changsure-core-service/internal/modules/service_category"

	"gorm.io/gorm"
)

type TechnicianPost struct {
	ID           uint `gorm:"primaryKey"`
	TechnicianID uint `gorm:"not null"`

	Title       string `gorm:"size:150;not null"`
	Description *string

	ServiceCategoryID *uint
	ServiceID         *uint
	ProvinceID        *uint

	IsPublished bool           `gorm:"default:true"`
	CreatedAt   time.Time      `gorm:"autoCreateTime"`
	UpdatedAt   time.Time      `gorm:"autoUpdateTime"`
	DeletedAt   gorm.DeletedAt `gorm:"index"`

	Category *sc.ServiceCategory   `gorm:"foreignKey:ServiceCategoryID"`
	Service  *sv.Service           `gorm:"foreignKey:ServiceID"`
	Province *pv.Province          `gorm:"foreignKey:ProvinceID"`
	Images   []TechnicianPostImage `gorm:"foreignKey:PostID"`
}

func (TechnicianPost) TableName() string { return "technician_posts" }

type TechnicianPostImage struct {
	ID        uint `gorm:"primaryKey"`
	PostID    uint `gorm:"not null"`
	ImageURL  string
	SortOrder int

	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt gorm.DeletedAt `gorm:"index"`
}

func (TechnicianPostImage) TableName() string { return "technician_post_images" }

const (
	ReportSeverityWarning   = "WARNING"
	ReportSeverityBlacklist = "BLACKLIST"
)

type TechnicianPostReport struct {
	ID           uint `gorm:"primaryKey;autoIncrement"`
	PostID       uint `gorm:"not null;index"`
	TechnicianID uint `gorm:"not null;index"`
	AdminID      uint `gorm:"not null;index"`

	ReportType string  `gorm:"size:100;not null"`
	Reason     *string `gorm:"type:text"`
	Severity   string  `gorm:"size:20;not null"`

	DeletePost bool `gorm:"default:false"`

	CreatedAt time.Time `gorm:"autoCreateTime"`

	Post  *TechnicianPost `gorm:"foreignKey:PostID"`
	Admin *admin.Admin    `gorm:"foreignKey:AdminID"`
}

func (TechnicianPostReport) TableName() string { return "technician_post_reports" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianPost{},
		&TechnicianPostImage{},
		&TechnicianPostReport{},
	}
}
