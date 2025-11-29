package technician_addresses

import (
	"time"
)

type TechnicianAddress struct {
	ID           uint   `gorm:"primaryKey;autoIncrement" json:"id"`
	TechnicianID uint   `gorm:"index;not null" json:"technician_id"`
	AddressLine  string `gorm:"type:varchar(255);not null" json:"address_line"`
	SubDistrict  string `gorm:"type:varchar(100);not null" json:"sub_district"`
	District     string `gorm:"type:varchar(100);not null" json:"district"`
	Province     string `gorm:"type:varchar(100);not null" json:"province"`
	PostalCode   string `gorm:"type:varchar(10);not null" json:"postal_code"`

	Latitude  float64 `gorm:"not null" json:"latitude"`
	Longitude float64 `gorm:"not null" json:"longitude"`

	IsPrimary bool `gorm:"default:false" json:"is_primary"`

	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

func (TechnicianAddress) TableName() string { return "technician_addresses" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianAddress{},
	}
}
