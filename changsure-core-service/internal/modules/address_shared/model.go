package addressshared

import (
	"changsure-core-service/internal/modules/district"
	"changsure-core-service/internal/modules/province"
	subdistrict "changsure-core-service/internal/modules/sub_district"
)

type AddressFields struct {
	Label       *string `gorm:"type:varchar(50)" json:"label"`
	PhoneNumber *string `gorm:"type:varchar(10)" json:"phone_number"`

	AddressLine *string `gorm:"type:varchar(255)" json:"address_line"`

	HouseNumber *string `gorm:"type:varchar(50)" json:"house_number"`
	Village     *string `gorm:"type:varchar(100)" json:"village"`
	Moo         *string `gorm:"type:varchar(10)" json:"moo"`
	Soi         *string `gorm:"type:varchar(100)" json:"soi"`
	Road        *string `gorm:"type:varchar(100)" json:"road"`

	ProvinceID    *uint `gorm:"index" json:"province_id"`
	DistrictID    *uint `gorm:"index" json:"district_id"`
	SubDistrictID *uint `gorm:"index" json:"sub_district_id"`

	Latitude  *float64 `gorm:"type:decimal(11,8)" json:"latitude"`
	Longitude *float64 `gorm:"type:decimal(11,8)" json:"longitude"`

	IsPrimary bool `gorm:"default:false" json:"is_primary"`

	Province    *province.Province       `gorm:"foreignKey:ProvinceID" json:"province,omitempty"`
	District    *district.District       `gorm:"foreignKey:DistrictID" json:"district,omitempty"`
	SubDistrict *subdistrict.SubDistrict `gorm:"foreignKey:SubDistrictID" json:"sub_district,omitempty"`
}
