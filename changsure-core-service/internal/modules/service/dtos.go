package service

type MenuPriceRange struct {
	Min float64  `json:"min"`
	Max *float64 `json:"max,omitempty"`
}

type ServiceMenuResponse struct {
	ID             uint           `json:"id"`
	SerName        string         `json:"ser_name"`
	SerDescription *string        `json:"ser_description"`
	ImageURLs      []string       `json:"image_urls"`
	Price          MenuPriceRange `json:"price"`
	PriceSource    string         `json:"price_source"`
	IsActive       bool           `json:"is_active"`
	CategoryID     uint           `json:"category_id"`
	CategoryName   *string        `json:"category_name,omitempty"`
}

type ListMenuQuery struct {
	ProvinceID uint
	CategoryID *uint
	IsActive   *bool
}

type MenuQuery struct {
	ProvinceID uint
	CategoryID *uint
	IsActive   *bool
}

type MenuPrice struct {
	Type string   `json:"type"`
	Min  float64  `json:"min"`
	Max  *float64 `json:"max,omitempty"`
}

type ServiceMenuCard struct {
	ID              uint      `json:"id"`
	SerName         string    `json:"ser_name"`
	ThumbnailURL    *string   `json:"thumbnail_url"`
	Price           MenuPrice `json:"price"`
	PriceSource     string    `json:"price_source"`
	TechnicianCount int       `json:"technician_count"`
	Available       bool      `json:"available"`
}

type CategoryMenuGroup struct {
	CategoryID   uint              `json:"category_id"`
	CategoryName string            `json:"category_name"`
	CategoryIcon *string           `json:"category_icon"`
	Services     []ServiceMenuCard `json:"services"`
}

type ServiceMenuDetail struct {
	ID              uint      `json:"id"`
	SerName         string    `json:"ser_name"`
	SerDescription  *string   `json:"ser_description"`
	SerDetails      []string  `json:"ser_details"`
	AdditionalTerms []string  `json:"additional_terms"`
	WorkingDuration []string  `json:"working_duration"`
	ImageURLs       []string  `json:"image_urls"`
	Price           MenuPrice `json:"price"`
	PriceSource     string    `json:"price_source"`
	TechnicianCount int       `json:"technician_count"`
	CategoryID      uint      `json:"category_id"`
	CategoryName    *string   `json:"category_name"`
	Available       bool      `json:"available"`
}

type CreateServiceRequest struct {
	CategoryID uint   `json:"category_id" validate:"required,min=1"`
	SerName    string `json:"ser_name" validate:"required,min=2,max=190"`

	SerDescription  *string     `json:"ser_description" validate:"omitempty,max=5000"`
	SerDetails      StringArray `json:"ser_details" validate:"omitempty,dive,max=5000"`
	AdditionalTerms StringArray `json:"additional_terms" validate:"omitempty,dive,max=5000"`
	WorkingDuration StringArray `json:"working_duration" validate:"omitempty,dive,max=5000"`

	ImageURLs    StringArray `json:"image_urls" validate:"omitempty,dive,url"`
	DefaultPrice JSONMap     `json:"default_price"`

	IsActive *bool `json:"is_active" validate:"omitempty"`
}

type UpdateServiceRequest struct {
	CategoryID *uint   `json:"category_id" validate:"omitempty,min=1"`
	SerName    *string `json:"ser_name" validate:"omitempty,min=2,max=190"`

	SerDescription  *string      `json:"ser_description" validate:"omitempty,max=5000"`
	SerDetails      *StringArray `json:"ser_details" validate:"omitempty,dive,max=5000"`
	AdditionalTerms *StringArray `json:"additional_terms" validate:"omitempty,dive,max=5000"`
	WorkingDuration *StringArray `json:"working_duration" validate:"omitempty,dive,max=5000"`

	ImageURLs    *StringArray `json:"image_urls" validate:"omitempty,dive,url"`
	DefaultPrice *JSONMap     `json:"default_price"`

	IsActive *bool `json:"is_active" validate:"omitempty"`
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

type ServiceResponse struct {
	ID              uint                   `json:"id"`
	SerName         string                 `json:"ser_name"`
	SerDescription  *string                `json:"ser_description"`
	SerDetails      []string               `json:"ser_details"`
	AdditionalTerms []string               `json:"additional_terms"`
	WorkingDuration []string               `json:"working_duration"`
	ImageURLs       []string               `json:"image_urls"`
	DefaultPrice    map[string]interface{} `json:"default_price"`
	IsActive        bool                   `json:"is_active"`
	CategoryID      uint                   `json:"category_id"`
	CategoryName    *string                `json:"category_name,omitempty"`

	CreatedAt string `json:"created_at"`
	UpdatedAt string `json:"updated_at"`
}
