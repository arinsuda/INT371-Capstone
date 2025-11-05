package technicians

import (
	provinces "changsure-core-service/internal/modules/provinces"
)

type TechnicianProfileReq struct {
	FirstName string  `json:"firstname"    validate:"required,min=2,max=150"`
	LastName  string  `json:"lastname"     validate:"required,min=2,max=150"`
	Bio       *string `json:"bio"          validate:"omitempty,max=2000"`
	Phone     *string `json:"phone"        validate:"omitempty,e164phone"`
	Email     *string `json:"email"        validate:"omitempty,email,max=100"`
	AvatarURL *string `json:"avatar_url"   validate:"omitempty,url,max=255"`

	ProvinceIDs []uint `json:"province_ids" validate:"omitempty,dive,min=1"`
}

type TechServiceRes struct {
	AreaID      uint     `json:"area_id"`
	ProvinceID  uint     `json:"province_id"`
	ServiceID   uint     `json:"service_id"`
	ServiceName string   `json:"service_name"`
	CategoryID  *uint    `json:"category_id,omitempty"`
	Category    *string  `json:"category_name,omitempty"`
	PricingType string   `json:"pricing_type"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}

type TechnicianProfileRes struct {
	ID        uint    `json:"id"`
	FirstName string  `json:"firstname"`
	LastName  string  `json:"lastname"`
	Bio       *string `json:"bio,omitempty"`
	Phone     *string `json:"phone,omitempty"`
	Email     *string `json:"email,omitempty"`
	AvatarURL *string `json:"avatar_url,omitempty"`

	RatingAvg   *float64 `json:"rating_avg,omitempty"`
	RatingCount uint     `json:"rating_count"`
	TotalJobs   uint     `json:"total_jobs"`
	IsAvailable bool     `json:"is_available"`
	IsVerified  bool     `json:"is_verified"`

	Provinces []provinces.ProvinceResponse `json:"provinces"`
	Services  []TechServiceRes             `json:"services"`
}

type TechnicianProvincesPatchReq struct {
	ProvinceIDs []uint `json:"province_ids" validate:"required,min=1,dive,gt=0"`
}
