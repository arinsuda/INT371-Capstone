package subdistrict

import (
	"changsure-core-service/internal/modules/district"
	"time"
)

type SubDistrict struct {
	ID         uint   `gorm:"primaryKey;autoIncrement" json:"id"`
	NameTH     string `gorm:"type:varchar(150);not null" json:"name_th"`
	PostalCode string `gorm:"type:varchar(10);not null" json:"postal_code"`
	DistrictID uint   `gorm:"not null;index" json:"district_id"`

	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`

	District district.District `gorm:"foreignKey:DistrictID" json:"district,omitempty"`
}

func (SubDistrict) TableName() string { return "sub_districts" }

func Models() []interface{} {
	return []interface{}{&SubDistrict{}}
}
