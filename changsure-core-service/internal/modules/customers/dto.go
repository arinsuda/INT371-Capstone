package customers

import (
	"errors"
	"strings"

)

// CreateCustomerRequest DTO for creating a customer
type CreateCustomerRequest struct {
	FullName   string   `json:"fullname" validate:"required,min=2,max=190"`
	Phone      *string  `json:"phone" validate:"omitempty,min=10,max=32"`
	Address    *string  `json:"address" validate:"omitempty,max=500"`
	Latitude   *float64 `json:"latitude" validate:"omitempty,min=-90,max=90"`
	Longitude  *float64 `json:"longitude" validate:"omitempty,min=-180,max=180"`
	ProvinceID *uint    `json:"province_id" validate:"omitempty,min=1"`
}

// Validate validates the create request
func (r *CreateCustomerRequest) Validate() error {
	if strings.TrimSpace(r.FullName) == "" {
		return errors.New("fullname is required")
	}
	if len(r.FullName) < 2 || len(r.FullName) > 190 {
		return errors.New("fullname must be between 2 and 190 characters")
	}

	// If coordinates provided, both must be present
	if (r.Latitude != nil && r.Longitude == nil) || (r.Latitude == nil && r.Longitude != nil) {
		return errors.New("both latitude and longitude must be provided together")
	}

	if r.Latitude != nil {
		if *r.Latitude < -90 || *r.Latitude > 90 {
			return errors.New("latitude must be between -90 and 90")
		}
	}

	if r.Longitude != nil {
		if *r.Longitude < -180 || *r.Longitude > 180 {
			return errors.New("longitude must be between -180 and 180")
		}
	}

	return nil
}

// UpdateCustomerRequest DTO for updating a customer
type UpdateCustomerRequest struct {
	FullName   *string  `json:"fullname" validate:"omitempty,min=2,max=190"`
	Phone      *string  `json:"phone" validate:"omitempty,min=10,max=32"`
	Address    *string  `json:"address" validate:"omitempty,max=500"`
	Latitude   *float64 `json:"latitude" validate:"omitempty,min=-90,max=90"`
	Longitude  *float64 `json:"longitude" validate:"omitempty,min=-180,max=180"`
	ProvinceID *uint    `json:"province_id" validate:"omitempty,min=1"`
}

// Validate validates the update request
func (r *UpdateCustomerRequest) Validate() error {
	if r.FullName != nil {
		if len(*r.FullName) < 2 || len(*r.FullName) > 190 {
			return errors.New("fullname must be between 2 and 190 characters")
		}
	}

	if r.Latitude != nil {
		if *r.Latitude < -90 || *r.Latitude > 90 {
			return errors.New("latitude must be between -90 and 90")
		}
	}

	if r.Longitude != nil {
		if *r.Longitude < -180 || *r.Longitude > 180 {
			return errors.New("longitude must be between -180 and 180")
		}
	}

	return nil
}

// CustomerResponse DTO for API responses
type CustomerResponse struct {
	ID        uint    `json:"id"`
	FullName  string  `json:"fullname"`
	Phone     *string `json:"phone,omitempty"`
	Address   *string `json:"address,omitempty"`
	Latitude  *float64 `json:"latitude,omitempty"`
	Longitude *float64 `json:"longitude,omitempty"`
	Province  *ProvinceResponse `json:"province,omitempty"`
	CreatedAt string  `json:"created_at"`
}

// ProvinceResponse nested province info
type ProvinceResponse struct {
	ID       uint   `json:"id"`
	NameTH   string `json:"name_th"`
	NameEN   string `json:"name_en"`
}

// ToResponse converts Customer model to response DTO
func ToResponse(c *Customer) *CustomerResponse {
	resp := &CustomerResponse{
		ID:        c.ID,
		FullName:  c.FullName,
		Phone:     c.Phone,
		Address:   c.Address,
		Latitude:  c.Latitude,
		Longitude: c.Longitude,
		CreatedAt: c.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	}

	if c.Province != nil {
		resp.Province = &ProvinceResponse{
			ID:     c.Province.ID,
			NameTH: c.Province.NameTH,
			NameEN: *c.Province.NameEN,
		}
	}

	return resp
}

// ToResponseList converts multiple customers to response DTOs
func ToResponseList(customers []*Customer) []*CustomerResponse {
	responses := make([]*CustomerResponse, len(customers))
	for i, c := range customers {
		responses[i] = ToResponse(c)
	}
	return responses
}

// SearchNearbyRequest DTO for nearby search
type SearchNearbyRequest struct {
	Latitude  float64 `json:"latitude" validate:"required,min=-90,max=90"`
	Longitude float64 `json:"longitude" validate:"required,min=-180,max=180"`
	RadiusKm  float64 `json:"radius_km" validate:"required,min=0.1,max=100"`
}

// Validate validates nearby search request
func (r *SearchNearbyRequest) Validate() error {
	if r.Latitude < -90 || r.Latitude > 90 {
		return errors.New("latitude must be between -90 and 90")
	}
	if r.Longitude < -180 || r.Longitude > 180 {
		return errors.New("longitude must be between -180 and 180")
	}
	if r.RadiusKm <= 0 || r.RadiusKm > 100 {
		return errors.New("radius must be between 0.1 and 100 km")
	}
	return nil
}