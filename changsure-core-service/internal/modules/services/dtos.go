package services

type CreateServiceRequest struct {
	CategoryID uint   `json:"category_id" validate:"required,min=1"`
	SerName    string `json:"ser_name" validate:"required,min=2,max=190"`

	SerDescription  *string     `json:"ser_description" validate:"omitempty,dive,max=5000"`
	SerDetails      StringArray `json:"ser_details" validate:"omitempty,dive,max=5000"`
	AdditionalTerms StringArray `json:"additional_terms" validate:"omitempty,dive,max=5000"`
	WorkingDuration StringArray `json:"working_duration" validate:"omitempty,dive,max=5000"`

	ImageURL *string `json:"image_url" validate:"omitempty,url"`
	IsActive *bool   `json:"is_active" validate:"omitempty"`
}

type UpdateServiceRequest struct {
	CategoryID *uint   `json:"category_id" validate:"omitempty,min=1"`
	SerName    *string `json:"ser_name" validate:"omitempty,min=2,max=190"`

	SerDescription  *StringArray `json:"ser_description" validate:"omitempty,dive,max=5000"`
	SerDetails      *StringArray `json:"ser_details" validate:"omitempty,dive,max=5000"`
	AdditionalTerms *StringArray `json:"additional_terms" validate:"omitempty,dive,max=5000"`
	WorkingDuration *StringArray `json:"working_duration" validate:"omitempty,dive,max=5000"`

	ImageURL *string `json:"image_url" validate:"omitempty,url"`
	IsActive *bool   `json:"is_active" validate:"omitempty"`
}

type ListQuery struct {
	Search     string
	CategoryID *uint
	IsActive   *bool

	Page     int
	PageSize int

	SortBy    string
	SortOrder string
}

type PriceType string

const (
	PriceTypeFixed PriceType = "fixed"
	PriceTypeRange PriceType = "range"
)

type DefaultPrice struct {
	Type  PriceType `json:"type"`
	Value *float64  `json:"value,omitempty"`
	Min   *float64  `json:"min,omitempty"`
	Max   *float64  `json:"max,omitempty"`
}
