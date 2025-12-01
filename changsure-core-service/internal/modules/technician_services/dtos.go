package technician_services

type TechnicianPricingReq struct {
	TechnicianID uint     `json:"technician_id" validate:"required"`
	ServiceID    uint     `json:"service_id"   validate:"required"`
	PricingType  string   `json:"pricing_type" validate:"required,oneof=FIXED RANGE"`
	PriceFixed   *float64 `json:"price_fixed"`
	PriceMin     *float64 `json:"price_min"`
	PriceMax     *float64 `json:"price_max"`
	IsActive     *bool    `json:"is_active"`
}

type SearchTechniciansQuery struct {
	ProvinceID *uint    `query:"province_id"`
	ServiceID  uint     `query:"service_id"  validate:"required"`
	PriceMin   *float64 `query:"price_min"`
	PriceMax   *float64 `query:"price_max"`
	RatingMin  *float64 `query:"rating_min"`
	Sort       string   `query:"sort"`
	Page       int      `query:"page"`
	PageSize   int      `query:"page_size"`
}

type TechnicianServicePatchReq struct {
	ServiceID   uint     `json:"service_id"`
	PricingType string   `json:"pricing_type"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}

type UpdateTechServiceReq struct {
	ServiceID   uint     `json:"service_id" validate:"required"`
	PricingType string   `json:"pricing_type,omitempty"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}
