package addressshared

type NearbyQuery struct {
	Lat float64 `json:"lat" validate:"required"`
	Lng float64 `json:"lng" validate:"required"`
	KM  float64 `json:"km" validate:"required,min=0.1,max=100"`

	Limit int    `json:"limit,omitempty"`
	Sort  string `json:"sort,omitempty"`
}

type NearbyTechnicianResult struct {
	TechnicianID uint    `json:"technician_id"`
	DistanceKM   float64 `json:"distance_km"`
	Province     string  `json:"province"`
	District     string  `json:"district"`
}
