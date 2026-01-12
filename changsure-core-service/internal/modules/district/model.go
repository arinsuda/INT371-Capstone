package district

import (
	"changsure-core-service/internal/modules/province"
	"time"
)

type District struct {
	ID         uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	NameTH     string    `gorm:"type:varchar(150);not null" json:"name_th"`
	ProvinceID uint      `gorm:"not null;index" json:"province_id"`
	
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt  time.Time `gorm:"autoUpdateTime" json:"updated_at"`

	Province   province.Province `gorm:"foreignKey:ProvinceID" json:"province,omitempty"`
}

func (District) TableName() string { return "districts" }

func Models() []interface{} {
	return []interface{}{&District{}}
}