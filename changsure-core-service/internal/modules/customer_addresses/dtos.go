package customeraddresses

import (
	"errors"
	"time"

	provinces "changsure-core-service/internal/modules/provinces"
)

type CreateCustomerAddressRequest struct {
	ProvinceID  uint     `json:"province_id" validate:"required,min=1"`
	HouseNumber *string  `json:"house_number" validate:"omitempty,max=20"`
	Village     *string  `json:"village"      validate:"omitempty,max=100"`
	Moo         *string  `json:"moo"          validate:"omitempty,max=10"`
	Soi         *string  `json:"soi"          validate:"omitempty,max=100"`
	Road        *string  `json:"road"         validate:"omitempty,max=100"`
	Subdistrict *string  `json:"subdistrict"  validate:"omitempty,max=100"`
	District    *string  `json:"district"     validate:"omitempty,max=100"`
	PostalCode  *string  `json:"postal_code"  validate:"omitempty,max=5"`
	Country     *string  `json:"country"      validate:"omitempty,max=100"`
	Latitude    *float64 `json:"latitude"     validate:"omitempty"`
	Longitude   *float64 `json:"longitude"    validate:"omitempty"`
}

func (r *CreateCustomerAddressRequest) Validate() error {
	if r.ProvinceID == 0 {
		return errors.New("province_id is required")
	}
	if r.PostalCode != nil && (!isDigits(*r.PostalCode) || len(*r.PostalCode) > 5) {
		return errors.New("postal_code must be digits and at most 5 characters")
	}
	return nil
}

type UpdateCustomerAddressRequest struct {
	ProvinceID  *uint    `json:"province_id" validate:"omitempty,min=1"`
	HouseNumber *string  `json:"house_number" validate:"omitempty,max=20"`
	Village     *string  `json:"village"      validate:"omitempty,max=100"`
	Moo         *string  `json:"moo"          validate:"omitempty,max=10"`
	Soi         *string  `json:"soi"          validate:"omitempty,max=100"`
	Road        *string  `json:"road"         validate:"omitempty,max=100"`
	Subdistrict *string  `json:"subdistrict"  validate:"omitempty,max=100"`
	District    *string  `json:"district"     validate:"omitempty,max=100"`
	PostalCode  *string  `json:"postal_code"  validate:"omitempty,max=5"`
	Country     *string  `json:"country"      validate:"omitempty,max=100"`
	Latitude    *float64 `json:"latitude"     validate:"omitempty"`
	Longitude   *float64 `json:"longitude"    validate:"omitempty"`
}

func (r *UpdateCustomerAddressRequest) Validate() error {
	if r.ProvinceID != nil && *r.ProvinceID == 0 {
		return errors.New("province_id must be >= 1 when provided")
	}
	if r.PostalCode != nil && (!isDigits(*r.PostalCode) || len(*r.PostalCode) > 5) {
		return errors.New("postal_code must be digits and at most 5 characters")
	}
	return nil
}

type CustomerAddressResponse struct {
	ID          uint                       `json:"id"`
	Province    provinces.ProvinceResponse `json:"province"`
	HouseNumber *string                    `json:"house_number,omitempty"`
	Village     *string                    `json:"village,omitempty"`
	Moo         *string                    `json:"moo,omitempty"`
	Soi         *string                    `json:"soi,omitempty"`
	Road        *string                    `json:"road,omitempty"`
	Subdistrict *string                    `json:"subdistrict,omitempty"`
	District    *string                    `json:"district,omitempty"`
	PostalCode  *string                    `json:"postal_code,omitempty"`
	Country     *string                    `json:"country,omitempty"`
	Latitude    *float64                   `json:"latitude,omitempty"`
	Longitude   *float64                   `json:"longitude,omitempty"`
	CreatedAt   string                     `json:"created_at"`
	UpdatedAt   string                     `json:"updated_at"`
}

func ToResponse(a *CustomerAddress) CustomerAddressResponse {
	resp := CustomerAddressResponse{
		ID:          a.ID,
		HouseNumber: a.HouseNumber,
		Village:     a.Village,
		Moo:         a.Moo,
		Soi:         a.Soi,
		Road:        a.Road,
		Subdistrict: a.Subdistrict,
		District:    a.District,
		PostalCode:  a.PostalCode,
		Country:     a.Country,
		Latitude:    a.Latitude,
		Longitude:   a.Longitude,
		CreatedAt:   a.CreatedAt.Format(time.RFC3339),
		UpdatedAt:   a.UpdatedAt.Format(time.RFC3339),
	}
	if a.Province != nil {
		resp.Province = provinces.ProvinceResponse{ID: a.Province.ID, NameTH: a.Province.NameTH}
	} else {
		resp.Province = provinces.ProvinceResponse{ID: a.ProvinceID}
	}
	return resp
}

func ToResponseList(arr []*CustomerAddress) []CustomerAddressResponse {
	out := make([]CustomerAddressResponse, 0, len(arr))
	for _, a := range arr {
		out = append(out, ToResponse(a))
	}
	return out
}

func isDigits(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if r < '0' || r > '9' {
			return false
		}
	}
	return true
}
