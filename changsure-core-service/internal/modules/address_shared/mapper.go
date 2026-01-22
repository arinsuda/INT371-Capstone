package addressshared

import "time"

func StrOrEmpty(v *string) string {
	if v == nil {
		return ""
	}
	return *v
}

func UintOrZero(v *uint) uint {
	if v == nil {
		return 0
	}
	return *v
}

func FloatOrZero(v *float64) float64 {
	if v == nil {
		return 0
	}
	return *v
}

func TimeRFC3339(t time.Time) string {
	if t.IsZero() {
		return ""
	}
	return t.Format(time.RFC3339)
}

type BaseAddressResponse struct {
	ID uint `json:"id"`

	Label       string `json:"label"`
	PhoneNumber string `json:"phone_number"`

	HouseNumber string `json:"house_number"`
	Village     string `json:"village"`
	Moo         string `json:"moo"`
	Soi         string `json:"soi"`
	Road        string `json:"road"`

	SubDistrictID uint `json:"sub_district_id"`
	DistrictID    uint `json:"district_id"`
	ProvinceID    uint `json:"province_id"`

	SubDistrictName string `json:"sub_district_name"`
	DistrictName    string `json:"district_name"`
	ProvinceName    string `json:"province_name"`
	PostalCode      string `json:"postal_code"`

	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	IsPrimary bool    `json:"is_primary"`

	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}
