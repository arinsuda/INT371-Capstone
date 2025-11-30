package technician_addresses

import (
	"time"
	"changsure-core-service/internal/modules/address_shared"
)

type CreateTechnicianAddressRequest struct {
	HouseNumber *string `json:"house_number"`
	Village     *string `json:"village"`
	Moo         *string `json:"moo"`
	Soi         *string `json:"soi"`
	Road        *string `json:"road"`

	SubDistrict *string `json:"sub_district"`
	District    *string `json:"district"`
	Province    *string `json:"province"`

	PostalCode *string `json:"postal_code"`
	Country    *string `json:"country"`

	ProvinceID *uint `json:"province_id"`

	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`

	IsPrimary *bool `json:"is_primary"`
}

type UpdateTechnicianAddressRequest struct {
	HouseNumber *string `json:"house_number"`
	Village     *string `json:"village"`
	Moo         *string `json:"moo"`
	Soi         *string `json:"soi"`
	Road        *string `json:"road"`

	SubDistrict *string `json:"sub_district"`
	District    *string `json:"district"`
	Province    *string `json:"province"`

	PostalCode *string `json:"postal_code"`
	Country    *string `json:"country"`

	ProvinceID *uint `json:"province_id"`

	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`

	IsPrimary *bool `json:"is_primary"`
}

type NearbyTechnicianRequest struct {
	address_shared.NearbyQuery
}

type TechnicianAddressResponse struct {
	ID          uint    `json:"id"`
	HouseNumber *string `json:"house_number"`
	Village     *string `json:"village"`
	Moo         *string `json:"moo"`
	Soi         *string `json:"soi"`
	Road        *string `json:"road"`

	SubDistrict *string `json:"sub_district"`
	District    *string `json:"district"`
	Province    *string `json:"province"`

	PostalCode *string `json:"postal_code"`
	Country    *string `json:"country"`

	ProvinceID *uint `json:"province_id"`

	Latitude  *float64 `json:"latitude"`
	Longitude *float64 `json:"longitude"`

	IsPrimary bool `json:"is_primary"`

	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}

func ToResponse(a *TechnicianAddress) TechnicianAddressResponse {
	if a == nil {
		return TechnicianAddressResponse{}
	}

	return TechnicianAddressResponse{
		ID:          a.ID,
		HouseNumber: a.HouseNumber,
		Village:     a.Village,
		Moo:         a.Moo,
		Soi:         a.Soi,
		Road:        a.Road,
		SubDistrict: a.SubDistrict,
		District:    a.District,
		Province:    a.Province,
		PostalCode:  a.PostalCode,
		Country:     a.Country,
		ProvinceID:  a.ProvinceID,
		Latitude:    a.Latitude,
		Longitude:   a.Longitude,
		IsPrimary:   a.IsPrimary,
		CreatedAt:   a.CreatedAt.Format(time.RFC3339),
		UpdatedAt:   a.UpdatedAt.Format(time.RFC3339),
	}
}

func ToResponseList(items []*TechnicianAddress) []TechnicianAddressResponse {
	out := make([]TechnicianAddressResponse, 0, len(items))
	for _, item := range items {
		out = append(out, ToResponse(item))
	}
	return out
}
