package addressshared

import (
	"strings"
	"time"
)

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

	AddressLine string `json:"address_line"`

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

func BuildAddressLine(house, moo, village, soi, road *string) string {
	parts := []string{}

	if house != nil && *house != "" {
		parts = append(parts, *house)
	}
	if moo != nil && *moo != "" {
		parts = append(parts, "หมู่ "+*moo)
	}
	if village != nil && *village != "" {
		parts = append(parts, *village)
	}
	if soi != nil && *soi != "" {
		parts = append(parts, "ซ."+*soi)
	}
	if road != nil && *road != "" {
		parts = append(parts, "ถ."+*road)
	}

	return strings.Join(parts, " ")
}

func FirstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}
