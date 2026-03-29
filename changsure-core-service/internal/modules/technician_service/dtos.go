package technicianservice

type UpsertPricingReq struct {
	ServiceID   uint     `json:"service_id"   validate:"required,gt=0"`
	PricingType string   `json:"pricing_type" validate:"required,oneof=FIXED RANGE"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
	IsActive    *bool    `json:"is_active,omitempty"`
}

type ServicePatchItem struct {
	ServiceID   uint     `json:"service_id"`
	PricingType string   `json:"pricing_type"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
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

func (q *SearchTechniciansQuery) SetDefaults() {
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 || q.PageSize > 50 {
		q.PageSize = 20
	}
}

type SearchTechnicianItem struct {
	ID          uint     `gorm:"column:id"           json:"id"`
	FirstName   string   `gorm:"column:firstname"    json:"firstname"`
	LastName    string   `gorm:"column:lastname"     json:"lastname"`
	AvatarURL   *string  `gorm:"column:avatar_url"   json:"avatar_url,omitempty"`
	RatingAvg   *float64 `gorm:"column:rating_avg"   json:"rating_avg,omitempty"`
	RatingCount uint     `gorm:"column:rating_count" json:"rating_count"`
	PriceFrom   *float64 `gorm:"column:price_from"   json:"price_from,omitempty"`
}

type SearchTechnicianResult struct {
	Items    []SearchTechnicianItem `json:"items"`
	Total    int64                  `json:"total"`
	Page     int                    `json:"page"`
	PageSize int                    `json:"page_size"`
}
