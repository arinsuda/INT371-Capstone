package technicianposts

import (
	"mime/multipart"
	"time"
)

type CreateTechnicianPostDTO struct {
	Title       string  `form:"title"`
	Description *string `form:"description"`

	ServiceID  *uint      `form:"service_id"`
	ProvinceID *uint      `form:"province_id"`
	PostDate   *time.Time `form:"post_date"`

	Images []*multipart.FileHeader `form:"images"`
}

type UpdateTechnicianPostDTO struct {
	Title       *string `form:"title"`
	Description *string `form:"description"`
	ServiceID   *uint   `form:"service_id"`
	ProvinceID  *uint   `form:"province_id"`
	IsPublished *bool   `form:"is_published"`

	NewImages []*multipart.FileHeader `form:"new_images"`

	ImageIDsToDelete []uint `form:"image_ids_to_delete[]"`
}

type ListTechnicianPostsQuery struct {
	ServiceID  *uint `query:"service_id"`
	ProvinceID *uint `query:"province_id"`

	Search      string `query:"search"`
	IsPublished *bool  `query:"is_published"`
	CategoryID  *uint  `query:"category_id"`

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

	ServiceID   *uint   `json:"service_id"`
	ServiceName *string `json:"service_name"`

	CategoryID   *uint   `json:"category_id"`
	CategoryName *string `json:"category_name"`

	ProvinceID   *uint   `json:"province_id"`
	ProvinceName *string `json:"province_name"`

	Images []TechnicianPostImageResponse `json:"images"`

	IsPublished bool  `json:"is_published"`
	CreatedAt   int64 `json:"created_at"`
}
