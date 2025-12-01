package technicians

import (
	badges "changsure-core-service/internal/modules/badge"
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

	Provinces      []provinces.ProvinceResponse `json:"provinces"`
	Services       []TechServiceRes             `json:"services"`
	ServiceSummary []TechServiceSummary         `json:"service_summary"`
	Badges         []badges.BadgeResponse       `json:"badges"`
}

type TechnicianProvincesPatchReq struct {
	ProvinceIDs []uint `json:"province_ids" validate:"required,min=1,dive,gt=0"`
}

type AddTechServiceReq struct {
	ServiceID   uint     `json:"service_id"`
	PricingType string   `json:"pricing_type"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}

type TechServiceSummaryItem struct {
	ServiceID   uint   `json:"service_id"`
	ServiceName string `json:"service_name"`
}

type TechServiceSummary struct {
	ServiceCategoryID   uint                     `json:"service_category_id"`
	ServiceCategoryName string                   `json:"service_category_name"`
	Services            []TechServiceSummaryItem `json:"services"`
}

type RemoveTechServiceReq struct {
	ServiceID uint `json:"service_id"`
}

type UpdateTechServiceReq struct {
	PricingType string   `json:"pricing_type" validate:"required,oneof=FIXED RANGE fixed range"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}
