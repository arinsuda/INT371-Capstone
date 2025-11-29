package technician_addresses

type CreateTechAddressReq struct {
	AddressLine string `json:"address_line" validate:"required"`
	SubDistrict string `json:"sub_district" validate:"required"`
	District    string `json:"district" validate:"required"`
	Province    string `json:"province" validate:"required"`
	PostalCode  string `json:"postal_code" validate:"required"`

	Latitude  float64 `json:"latitude" validate:"required"`
	Longitude float64 `json:"longitude" validate:"required"`

	IsPrimary *bool `json:"is_primary" validate:"omitempty"`
}

type UpdateTechAddressReq struct {
	AddressLine *string `json:"address_line"`
	SubDistrict *string `json:"sub_district"`
	District    *string `json:"district"`
	Province    *string `json:"province"`
	PostalCode  *string `json:"postal_code"`

	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`

	IsPrimary *bool `json:"is_primary"`
}

type NearQuery struct {
	Lat float64
	Lng float64
	KM  float64
}
