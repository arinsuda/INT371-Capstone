package technicianaddress

import (
	addressshared "changsure-core-service/internal/modules/address_shared"
	"time"
)

type CreateTechnicianAddressRequest struct {
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

	IsPrimary *bool `json:"is_primary"`
}

type UpdateTechnicianAddressRequest struct {
	Label *string `json:"label" validate:"omitempty,max=50"`

	HouseNumber *string `json:"house_number"`
	Village     *string `json:"village"`
	Moo         *string `json:"moo"`
	Soi         *string `json:"soi"`
	Road        *string `json:"road"`

	SubDistrictID *uint `json:"sub_district_id"`
	DistrictID    *uint `json:"district_id"`
	ProvinceID    *uint `json:"province_id"`

	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`

	IsPrimary *bool `json:"is_primary"`
}

type NearbyTechnicianRequest struct {
	addressshared.NearbyQuery
}

type TechnicianAddressResponse struct {
	ID uint `json:"id"`

	Label       *string `json:"label,omitempty"`
	PhoneNumber *string `json:"phone_number,omitempty"`

	HouseNumber *string `json:"house_number"`
	Village     *string `json:"village"`
	Moo         *string `json:"moo"`
	Soi         *string `json:"soi"`
	Road        *string `json:"road"`

	SubDistrictID uint `json:"sub_district_id"`
	DistrictID    uint `json:"district_id"`
	ProvinceID    uint `json:"province_id"`

	SubDistrictName string `json:"sub_district_name,omitempty"`
	DistrictName    string `json:"district_name,omitempty"`
	ProvinceName    string `json:"province_name,omitempty"`
	PostalCode      string `json:"postal_code,omitempty"`

	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`
	IsPrimary bool     `json:"is_primary"`

	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

func ToResponse(a *TechnicianAddress, phone *string) TechnicianAddressResponse {
	if a == nil {
		return TechnicianAddressResponse{}
	}

	resp := TechnicianAddressResponse{
		ID:          a.ID,
		Label:       a.Label,
		PhoneNumber: phone,
		HouseNumber: a.HouseNumber,
		Village:     a.Village,
		Moo:         a.Moo,
		Soi:         a.Soi,
		Road:        a.Road,
		Latitude:    a.Latitude,
		Longitude:   a.Longitude,
		IsPrimary:   a.IsPrimary,
		CreatedAt:   a.CreatedAt.Format(time.RFC3339),
		UpdatedAt:   a.UpdatedAt.Format(time.RFC3339),
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

func ToResponseList(items []*TechnicianAddress, phone *string) []TechnicianAddressResponse {
	out := make([]TechnicianAddressResponse, 0, len(items))
	for _, item := range items {
		out = append(out, ToResponse(item, phone))
	}
	return out
}
