package service_categories

import "time"

type ServiceCategory struct {
	ID          uint      `gorm:"primaryKey;autoIncrement"`
	Name        string    `gorm:"type:varchar(190);not null"`
	Description *string   `gorm:"type:text"`
	IconURL     *string   `gorm:"type:varchar(500)"`
	SortOrder   uint       `gorm:"not null;default:0;index:idx_service_categories_sort"`
	IsActive    bool      `gorm:"not null;default:true;index:idx_service_categories_active"`
	CreatedAt   time.Time `gorm:"autoCreateTime"`
	UpdatedAt   time.Time `gorm:"autoUpdateTime"`
}

func (ServiceCategory) TableName() string { return "service_categories" }

func Models() []interface{} {
	return []interface{}{
		&ServiceCategory{},
	}
}