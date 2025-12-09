package addressshared

type AddressFields struct {
	HouseNumber *string `gorm:"type:varchar(50)" json:"house_number"`
	Village     *string `gorm:"type:varchar(100)" json:"village"`
	Moo         *string `gorm:"type:varchar(10)" json:"moo"`
	Soi         *string `gorm:"type:varchar(100)" json:"soi"`
	Road        *string `gorm:"type:varchar(100)" json:"road"`

	SubDistrict *string `gorm:"type:varchar(100)" json:"sub_district"`
	District    *string `gorm:"type:varchar(100)" json:"district"`
	Province    *string `gorm:"type:varchar(100)" json:"province"`

	PostalCode *string `gorm:"type:varchar(10)" json:"postal_code"`
	Country    *string `gorm:"type:varchar(100)" json:"country"`

	ProvinceID *uint `gorm:"index" json:"province_id"`

	Latitude  *float64 `gorm:"type:decimal(11,8)" json:"latitude"`
	Longitude *float64 `gorm:"type:decimal(11,8)" json:"longitude"`

	IsPrimary bool `gorm:"default:false" json:"is_primary"`
}
