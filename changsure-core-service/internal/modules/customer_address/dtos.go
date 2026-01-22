package customeraddress

import (
	addressshared "changsure-core-service/internal/modules/address_shared"
)

type CreateCustomerAddressRequest struct {
	Label *string `json:"label" validate:"omitempty,max=50"`

	HouseNumber *string `json:"house_number" validate:"required"`
	Village     *string `json:"village"`
	Moo         *string `json:"moo"`
	Soi         *string `json:"soi"`
	Road        *string `json:"road"`

	SubDistrictID *uint `json:"sub_district_id" validate:"required"`
	DistrictID    *uint `json:"district_id" validate:"required"`
	ProvinceID    *uint `json:"province_id" validate:"required"`

	Latitude  *float64 `json:"latitude" validate:"required"`
	Longitude *float64 `json:"longitude" validate:"required"`
	IsPrimary *bool    `json:"is_primary"`
}

type UpdateCustomerAddressRequest struct {
	Label *string `json:"label" validate:"omitempty,max=50"`

	HouseNumber *string `json:"house_number" validate:"omitempty"`
	Village     *string `json:"village"`
	Moo         *string `json:"moo"`
	Soi         *string `json:"soi"`
	Road        *string `json:"road"`

	SubDistrictID *uint `json:"sub_district_id" validate:"omitempty"`
	DistrictID    *uint `json:"district_id" validate:"omitempty"`
	ProvinceID    *uint `json:"province_id" validate:"omitempty"`

	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`
	IsPrimary *bool    `json:"is_primary"`
}

type CustomerAddressResponse struct {
	addressshared.BaseAddressResponse
}

func ToResponse(a *CustomerAddress, phone *string) CustomerAddressResponse {
	if a == nil {
		return CustomerAddressResponse{}
	}

	resp := addressshared.BaseAddressResponse{
		ID:          a.ID,
		Label:       addressshared.StrOrEmpty(a.Label),
		PhoneNumber: addressshared.StrOrEmpty(phone),

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

	return CustomerAddressResponse{BaseAddressResponse: resp}
}

func ToResponseList(items []*CustomerAddress, phone *string) []CustomerAddressResponse {
	out := make([]CustomerAddressResponse, len(items))
	for i, item := range items {
		out[i] = ToResponse(item, phone)
	}
	return out
}
