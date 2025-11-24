package service_categories

import "time"

type ServiceCategory struct {
	ID        uint     `gorm:"primaryKey"`
	CatName   string     `gorm:"column:cat_name;size:190;uniqueIndex;not null"`
	CatDesc   *string    `gorm:"column:cat_description"`
	IconURL   *string    `gorm:"column:icon_url"`
	IsActive  bool       `gorm:"column:is_active;default:true"`
	CreatedAt time.Time  `gorm:"column:created_at"`
	UpdatedAt time.Time  `gorm:"column:updated_at"`
	DeletedAt *time.Time `gorm:"column:deleted_at"`
}

func (ServiceCategory) TableName() string { return "service_categories" }

func Models() []interface{} {
	return []interface{}{
		&ServiceCategory{},
	}
}
