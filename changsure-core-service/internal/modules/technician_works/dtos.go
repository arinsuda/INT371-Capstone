package technician_works

import "time"

type CreateTechnicianWorkDTO struct {
	Title       string  `json:"title" validate:"required,min=3,max=150"`
	Description *string `json:"description" validate:"omitempty,max=2000"`

	ServiceID  *uint      `json:"service_id" validate:"omitempty,gt=0"`
	ProvinceID *uint      `json:"province_id" validate:"omitempty,gt=0"`
	WorkDate   *time.Time `json:"work_date,omitempty"`

	ImageURLs []string `json:"image_urls"`
}

type UpdateTechnicianWorkDTO struct {
	Title       *string    `json:"title" validate:"omitempty,min=3,max=150"`
	Description *string    `json:"description" validate:"omitempty,max=2000"`
	ServiceID   *uint      `json:"service_id" validate:"omitempty,gt=0"`
	ProvinceID  *uint      `json:"province_id" validate:"omitempty,gt=0"`
	WorkDate    *time.Time `json:"work_date,omitempty"`
	IsPublished *bool      `json:"is_published,omitempty"`

	ImageURLs *[]string `json:"image_urls,omitempty"`
}

type ListTechnicianWorksQuery struct {
	TechnicianID uint  `query:"technician_id"`
	ServiceID    *uint `query:"service_id"`
	ProvinceID   *uint `query:"province_id"`

	Page    int `query:"page"`
	PerPage int `query:"per_page"`
}

type TechnicianWorkImageResponse struct {
	ID       uint   `json:"id"`
	ImageURL string `json:"image_url"`
	Order    int    `json:"order"`
}

type TechnicianWorkResponse struct {
	ID           uint `json:"id"`
	TechnicianID uint `json:"technician_id"`

	Title       string  `json:"title"`
	Description *string `json:"description,omitempty"`

	ServiceID    *uint   `json:"service_id,omitempty"`
	ServiceName  *string `json:"service_name,omitempty"`
	ProvinceID   *uint   `json:"province_id,omitempty"`
	ProvinceName *string `json:"province_name,omitempty"`

	WorkDate *time.Time                    `json:"work_date,omitempty"`
	Images   []TechnicianWorkImageResponse `json:"images"`

	IsPublished bool  `json:"is_published"`
	CreatedAt   int64 `json:"created_at"`
}
