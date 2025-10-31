package customeraddresses

import "errors"

type SearchNearbyRequest struct {
	Latitude  float64 `json:"latitude"  validate:"required"`
	Longitude float64 `json:"longitude" validate:"required"`
	RadiusKm  float64 `json:"radius_km" validate:"required,min=0.1,max=100"`
}

func (r *SearchNearbyRequest) Validate() error {
	if r.RadiusKm <= 0 || r.RadiusKm > 100 {
		return errors.New("radius must be between 0.1 and 100 km")
	}
	return nil
}