package technician

import (
	badges "changsure-core-service/internal/modules/badge"
	provinces "changsure-core-service/internal/modules/province"
	tsvc "changsure-core-service/internal/modules/technician_service"
	"time"
)

type TechnicianProfileReq struct {
	FirstName string  `json:"firstname"`
	LastName  string  `json:"lastname"`
	Bio       *string `json:"bio"`
	Phone     *string `json:"phone"`
	Email     *string `json:"email"`

	AvatarURL *string `json:"-"`

	ProvinceIDs []uint                  `json:"province_ids"`
	Services    []tsvc.ServicePatchItem `json:"services"`
}

type TechnicianProvincesPatchReq struct {
	ProvinceIDs []uint `json:"province_ids" validate:"required,min=1,dive,gt=0"`
}

type AddTechServiceReq struct {
	ServiceID   uint     `json:"service_id"   validate:"required,gt=0"`
	PricingType string   `json:"pricing_type" validate:"required,oneof=FIXED RANGE"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}

type UpdateTechServiceReq struct {
	ServiceID   uint     `json:"-"`
	PricingType string   `json:"pricing_type" validate:"omitempty,oneof=FIXED RANGE"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}

type RemoveTechServiceReq struct {
	ServiceID uint `json:"service_id"`
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

type TechServiceSummaryItem struct {
	ServiceID   uint   `json:"service_id"`
	ServiceName string `json:"service_name"`
}

type TechServiceSummary struct {
	ServiceCategoryID   uint                     `json:"service_category_id"`
	ServiceCategoryName string                   `json:"service_category_name"`
	Services            []TechServiceSummaryItem `json:"services"`
}

type TechServiceBrief struct {
	ID          uint     `json:"id"`
	Name        string   `json:"name"`
	PricingType string   `json:"pricing_type"`
	PriceFixed  *float64 `json:"price_fixed,omitempty"`
	PriceMin    *float64 `json:"price_min,omitempty"`
	PriceMax    *float64 `json:"price_max,omitempty"`
}

type TechServiceMutationResult struct {
	TechnicianID uint             `json:"technician_id"`
	Service      TechServiceBrief `json:"service"`
}

type TechnicianProfileRes struct {
	ID                 uint                         `json:"id"`
	FirstName          string                       `json:"firstname"`
	LastName           string                       `json:"lastname"`
	Bio                *string                      `json:"bio,omitempty"`
	Phone              *string                      `json:"phone,omitempty"`
	Email              *string                      `json:"email,omitempty"`
	AvatarURL          *string                      `json:"avatar_url,omitempty"`
	RatingAvg          float64                      `json:"rating_avg,omitempty"`
	RatingCount        int64                        `json:"rating_count"`
	TotalJobs          int64                        `json:"total_jobs"`
	IsAvailable        bool                         `json:"is_available"`
	VerificationStatus string                       `json:"verification_status"`
	TermsAccepted      bool                         `json:"terms_accepted"`
	PrivacyAccepted    bool                         `json:"privacy_accepted"`
	Provinces          []provinces.ProvinceResponse `json:"provinces"`
	Services           []TechServiceRes             `json:"services"`
	ServiceSummary     []TechServiceSummary         `json:"service_summary"`
	Badges             []badges.BadgeResponse       `json:"badges"`
}

type TechnicianStatus struct {
	IsAvailable        bool       `json:"is_available"`
	VerificationStatus string     `json:"verification_status"`
	AccountStatus      string     `json:"account_status"`
	WarningCount       int64      `json:"warning_count"`
	BannedAt           *time.Time `json:"banned_at,omitempty"`
}

type TechnicianResponseDashboard struct {
	ID        uint    `json:"id"`
	AvatarURL *string `json:"avatar_url,omitempty"`
	FirstName string  `json:"firstname"`
	LastName  string  `json:"lastname"`
	Email     *string `json:"email,omitempty"`
	Phone     *string `json:"phone,omitempty"`

	Provinces      []provinces.ProvinceResponse `json:"provinces"`
	Services       []TechServiceRes             `json:"services"`
	ServiceSummary []TechServiceSummary         `json:"service_summary"`

	TechnicianStatus
}

type TechnicianSummaryStats struct {
	Total         int64 `json:"total"`
	VerifiedCount int64 `json:"verified_count"`
	PendingCount  int64 `json:"pending_count"`
}

type TechnicianStats struct {
	TechnicianID uint    `gorm:"column:technician_id"`
	TotalJobs    int64   `gorm:"column:total_jobs"`
	RatingAvg    float64 `gorm:"column:rating_avg"`
	RatingCount  int64   `gorm:"column:rating_count"`
}
