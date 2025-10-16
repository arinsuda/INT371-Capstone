package customers

import (
	"time"
	"changsure-core-service/internal/modules/provinces"
)

type Customer struct {
	ID         uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	FullName   string    `gorm:"type:varchar(190);not null" json:"fullname"`
	Phone      *string   `gorm:"type:varchar(32)" json:"phone"`
	Address    *string   `gorm:"type:varchar(500)" json:"address"`
	Latitude   *float64  `gorm:"type:decimal(10,7);index:idx_customers_geo,priority:1" json:"latitude"`
	Longitude  *float64  `gorm:"type:decimal(10,7);index:idx_customers_geo,priority:2" json:"longitude"`
	CreatedAt  time.Time `gorm:"autoCreateTime" json:"created_at"`

	ProvinceID *uint     `gorm:"index:idx_customers_province" json:"province_id"`
	Province   *provinces.Province `gorm:"foreignKey:ProvinceID;constraint:OnUpdate:CASCADE,OnDelete:SET NULL" json:"province,omitempty"`
}

func (Customer) TableName() string { return "customers" }

func Models() []interface{} {
	return []interface{}{
		&Customer{},
	}
}
