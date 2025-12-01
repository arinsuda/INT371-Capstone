package technicians

import (
	badges "changsure-core-service/internal/modules/badge"
	provinces "changsure-core-service/internal/modules/provinces"
	tsvc "changsure-core-service/internal/modules/technician_services"
)

type TechnicianProfileReq struct {
	FirstName string  `json:"firstname"`
	LastName  string  `json:"lastname"`
	Bio       *string `json:"bio"`
	Phone     *string `json:"phone"`
	Email     *string `json:"email"`
	AvatarURL *string `json:"avatar_url"`

	ProvinceIDs []uint                      `json:"province_ids"`
	Services    []tsvc.TechnicianServicePatchReq `json:"services"`
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
