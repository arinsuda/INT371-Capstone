package services

type CreateServiceRequest struct {
	CategoryID     uint    `json:"category_id" validate:"required,min=1"`
	SerName        string  `json:"ser_name" validate:"required,min=2,max=190"`
	SerDescription *string `json:"ser_description" validate:"omitempty,max=5000"`
	ImageURL       *string `json:"image_url" validate:"omitempty,url"`
	IsActive       *bool   `json:"is_active" validate:"omitempty"`
}

type UpdateServiceRequest struct {
	CategoryID     *uint   `json:"category_id" validate:"omitempty,min=1"`
	SerName        *string `json:"ser_name" validate:"omitempty,min=2,max=190"`
	SerDescription *string `json:"ser_description" validate:"omitempty,max=5000"`
	ImageURL       *string `json:"image_url" validate:"omitempty,url"`
	IsActive       *bool   `json:"is_active" validate:"omitempty"`
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
