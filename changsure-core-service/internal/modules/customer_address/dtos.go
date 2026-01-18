package customeraddress

import (
	"time"
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

func ToResponse(a *CustomerAddress, phone *string) CustomerAddressResponse {
	if a == nil {
		return CustomerAddressResponse{}
	}

	resp := CustomerAddressResponse{
		ID: a.ID,

		Label:       "",
		PhoneNumber: "",

		HouseNumber: "",
		Village:     "",
		Moo:         "",
		Soi:         "",
		Road:        "",

		SubDistrictID: 0,
		DistrictID:    0,
		ProvinceID:    0,

		SubDistrictName: "",
		DistrictName:    "",
		ProvinceName:    "",
		PostalCode:      "",

		Latitude:  0,
		Longitude: 0,
		IsPrimary: a.IsPrimary,

		CreatedAt: a.CreatedAt.Format(time.RFC3339),
		UpdatedAt: a.UpdatedAt.Format(time.RFC3339),
	}

	if a.Label != nil {
		resp.Label = *a.Label
	}
	if phone != nil {
		resp.PhoneNumber = *phone
	}
	if a.HouseNumber != nil {
		resp.HouseNumber = *a.HouseNumber
	}
	if a.Village != nil {
		resp.Village = *a.Village
	}
	if a.Moo != nil {
		resp.Moo = *a.Moo
	}
	if a.Soi != nil {
		resp.Soi = *a.Soi
	}
	if a.Road != nil {
		resp.Road = *a.Road
	}

	if a.SubDistrictID != nil {
		resp.SubDistrictID = *a.SubDistrictID
	}
	if a.DistrictID != nil {
		resp.DistrictID = *a.DistrictID
	}
	if a.ProvinceID != nil {
		resp.ProvinceID = *a.ProvinceID
	}

	if a.Latitude != nil {
		resp.Latitude = *a.Latitude
	}
	if a.Longitude != nil {
		resp.Longitude = *a.Longitude
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

	return resp
}

func ToResponseList(items []*CustomerAddress, phone *string) []CustomerAddressResponse {
	out := make([]CustomerAddressResponse, len(items))
	for i, item := range items {
		out[i] = ToResponse(item, phone)
	}
	return out
}
