package customeraddresses

import (
	"changsure-core-service/internal/modules/provinces"
	"time"
)

type CustomerAddress struct {
	ID          uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	HouseNumber *string   `gorm:"type:varchar(20)" json:"house_number"`
	Village     *string   `gorm:"type:varchar(100)" json:"village"`
	Moo         *string   `gorm:"type:varchar(10)" json:"moo"`
	Soi         *string   `gorm:"type:varchar(100)" json:"soi"`
	Road        *string   `gorm:"type:varchar(100)" json:"road"`
	Subdistrict *string   `gorm:"type:varchar(100)" json:"subdistrict"`
	District    *string   `gorm:"type:varchar(100)" json:"district"`
	PostalCode  *string   `gorm:"type:varchar(5)" json:"postal_code"`
	Country     *string   `gorm:"type:varchar(100)" json:"country"`
	Latitude    *float64  `gorm:"type:decimal(11,8)" json:"latitude"`
	Longitude   *float64  `gorm:"type:decimal(11,8)" json:"longitude"`
	CreatedAt   time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt   time.Time `gorm:"autoUpdateTime" json:"updated_at"`

	CustomerID uint `gorm:"not null;index" json:"customer_id"`

	ProvinceID uint                `gorm:"index;not null" json:"province_id"`
	Province   *provinces.Province `gorm:"foreignKey:ProvinceID;constraint:OnUpdate:CASCADE,OnDelete:RESTRICT;" json:"province,omitempty"`
}

func Models() []interface{} {
	return []interface{}{
		&CustomerAddress{},
	}
}
