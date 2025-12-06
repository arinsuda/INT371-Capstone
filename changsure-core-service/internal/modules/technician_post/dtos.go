package technicianposts

import "time"

type CreateTechnicianPostDTO struct {
	Title       string  `json:"title" validate:"required,min=3,max=150"`
	Description *string `json:"description" validate:"omitempty,max=2000"`

	ServiceID  *uint      `json:"service_id"`
	ProvinceID *uint      `json:"province_id"`
	PostDate   *time.Time `json:"post_date"`

	ImageURLs []string `json:"image_urls"`
}

type UpdateTechnicianPostDTO struct {
	Title       *string    `json:"title" validate:"omitempty,min=3,max=150"`
	Description *string    `json:"description" validate:"omitempty,max=2000"`
	ServiceID   *uint      `json:"service_id"`
	ProvinceID  *uint      `json:"province_id"`
	PostDate    *time.Time `json:"post_date"`
	IsPublished *bool      `json:"is_published"`

	ImageURLs *[]string `json:"image_urls"`
}

type ListTechnicianPostsQuery struct {
	ServiceID  *uint `query:"service_id"`
	ProvinceID *uint `query:"province_id"`

	Page    int `query:"page"`
	PerPage int `query:"per_page"`
}

type TechnicianPostImageResponse struct {
	ID       uint   `json:"id"`
	ImageURL string `json:"image_url"`
	Order    int    `json:"order"`
}

type TechnicianPostResponse struct {
	ID           uint    `json:"id"`
	TechnicianID uint    `json:"technician_id"`
	Title        string  `json:"title"`
	Description  *string `json:"description"`

	ServiceID    *uint   `json:"service_id"`
	ServiceName  *string `json:"service_name"`
	ProvinceID   *uint   `json:"province_id"`
	ProvinceName *string `json:"province_name"`

	PostDate *time.Time                    `json:"post_date"`
	Images   []TechnicianPostImageResponse `json:"images"`

	IsPublished bool  `json:"is_published"`
	CreatedAt   int64 `json:"created_at"`
}
