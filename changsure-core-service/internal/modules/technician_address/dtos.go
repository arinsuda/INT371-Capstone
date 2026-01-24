package technicianaddress

import (
	addressshared "changsure-core-service/internal/modules/address_shared"
)

type CreateTechnicianAddressRequest struct {
	Label       *string `json:"label" validate:"omitempty,max=50"`
	PhoneNumber *string `json:"phone_number" validate:"omitempty,len=10"`

	AddressLine *string `json:"address_line" validate:"omitempty,max=255"`

	HouseNumber *string `json:"house_number" validate:"omitempty"`
	Village     *string `json:"village" validate:"omitempty"`
	Moo         *string `json:"moo" validate:"omitempty"`
	Soi         *string `json:"soi" validate:"omitempty"`
	Road        *string `json:"road" validate:"omitempty"`

	SubDistrictID *uint `json:"sub_district_id" validate:"required"`
	DistrictID    *uint `json:"district_id" validate:"required"`
	ProvinceID    *uint `json:"province_id" validate:"required"`

	Latitude  *float64 `json:"latitude" validate:"required"`
	Longitude *float64 `json:"longitude" validate:"required"`

	IsPrimary *bool `json:"is_primary" validate:"omitempty"`
}

type UpdateTechnicianAddressRequest struct {
	Label       *string `json:"label" validate:"omitempty,max=50"`
	PhoneNumber *string `json:"phone_number" validate:"omitempty,len=10"`

	AddressLine *string `json:"address_line" validate:"omitempty,max=255"`

	HouseNumber *string `json:"house_number" validate:"omitempty"`
	Village     *string `json:"village" validate:"omitempty"`
	Moo         *string `json:"moo" validate:"omitempty"`
	Soi         *string `json:"soi" validate:"omitempty"`
	Road        *string `json:"road" validate:"omitempty"`

	SubDistrictID *uint `json:"sub_district_id" validate:"omitempty"`
	DistrictID    *uint `json:"district_id" validate:"omitempty"`
	ProvinceID    *uint `json:"province_id" validate:"omitempty"`

	Latitude  *float64 `json:"latitude" validate:"omitempty"`
	Longitude *float64 `json:"longitude" validate:"omitempty"`

	IsPrimary *bool `json:"is_primary" validate:"omitempty"`
}

type NearbyTechnicianRequest struct {
	addressshared.NearbyQuery
}

type TechnicianAddressResponse struct {
	addressshared.BaseAddressResponse
}

func ToResponse(a *TechnicianAddress, defaultPhone *string) TechnicianAddressResponse {
	if a == nil {
		return TechnicianAddressResponse{}
	}

	finalPhone := resolvePhone(a.PhoneNumber, defaultPhone)

	resp := addressshared.BaseAddressResponse{
		ID:          a.ID,
		Label:       addressshared.StrOrEmpty(a.Label),
		PhoneNumber: addressshared.StrOrEmpty(finalPhone),

		AddressLine: addressshared.FirstNonEmpty(
			addressshared.StrOrEmpty(a.AddressLine),
			addressshared.BuildAddressLine(a.HouseNumber, a.Moo, a.Village, a.Soi, a.Road),
		),

		HouseNumber: addressshared.StrOrEmpty(a.HouseNumber),
		Village:     addressshared.StrOrEmpty(a.Village),
		Moo:         addressshared.StrOrEmpty(a.Moo),
		Soi:         addressshared.StrOrEmpty(a.Soi),
		Road:        addressshared.StrOrEmpty(a.Road),

		SubDistrictID: addressshared.UintOrZero(a.SubDistrictID),
		DistrictID:    addressshared.UintOrZero(a.DistrictID),
		ProvinceID:    addressshared.UintOrZero(a.ProvinceID),

		Latitude:  addressshared.FloatOrZero(a.Latitude),
		Longitude: addressshared.FloatOrZero(a.Longitude),

		IsPrimary: a.IsPrimary,
		CreatedAt: addressshared.TimeRFC3339(a.CreatedAt),
		UpdatedAt: addressshared.TimeRFC3339(a.UpdatedAt),
	}

	if a.SubDistrict != nil {
		resp.SubDistrictName = a.SubDistrict.NameTH
		resp.PostalCode = a.SubDistrict.PostalCode
	}
	if a.District != nil {
		resp.DistrictName = a.District.NameTH
	}
	if a.Province != nil {
		resp.ProvinceName = a.Province.NameTH
	}

	return TechnicianAddressResponse{BaseAddressResponse: resp}
}

func ToResponseList(items []*TechnicianAddress, phone *string) []TechnicianAddressResponse {
	out := make([]TechnicianAddressResponse, 0, len(items))
	for _, item := range items {
		out = append(out, ToResponse(item, phone))
	}
	return out
}

func resolvePhone(addrPhone *string, defaultPhone *string) *string {
	if addrPhone != nil && *addrPhone != "" {
		return addrPhone
	}
	return defaultPhone
}
