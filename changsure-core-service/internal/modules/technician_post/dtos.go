package technicianposts

import "mime/multipart"

type CreateTechnicianPostDTO struct {
	Title             string                  `form:"title"`
	Description       *string                 `form:"description"`
	ServiceCategoryID *uint                   `form:"service_category_id"`
	Images            []*multipart.FileHeader `form:"images"`
}

type UpdateTechnicianPostDTO struct {
	Title             *string                 `form:"title"`
	Description       *string                 `form:"description"`
	ServiceCategoryID *uint                   `form:"service_category_id"`
	IsPublished       *bool                   `form:"is_published"`
	NewImages         []*multipart.FileHeader `form:"new_images"`
	ImageIDsToDelete  []uint                  `form:"image_ids_to_delete[]"`
}

type ListTechnicianPostsQuery struct {
	ServiceID   *uint  `query:"service_id"`
	ProvinceID  *uint  `query:"province_id"`
	Search      string `query:"search"`
	IsPublished *bool  `query:"is_published"`
	CategoryID  *uint  `query:"category_id"`
	Page        int    `query:"page"`
	PerPage     int    `query:"per_page"`
}

func (q *ListTechnicianPostsQuery) SetDefaults() {
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PerPage < 1 || q.PerPage > 100 {
		q.PerPage = 20
	}
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

	Images      []TechnicianPostImageResponse `json:"images"`
	IsPublished bool                          `json:"is_published"`
	CreatedAt   int64                         `json:"created_at"`
}

type PostListResponse struct {
	Items   []TechnicianPostResponse `json:"items"`
	Total   int64                    `json:"total"`
	Page    int                      `json:"page"`
	PerPage int                      `json:"per_page"`
}

type CreatePostReportDTO struct {
	ReportType string  `json:"report_type" validate:"required"`
	Reason     *string `json:"reason"      validate:"omitempty,max=500"`
	Severity   string  `json:"severity"    validate:"required,oneof=WARNING BLACKLIST"`
	DeletePost bool    `json:"delete_post"`
}

type AdminResponse struct {
	ID        uint   `json:"id"`
	FirstName string `json:"first_name"`
	LastName  string `json:"last_name"`
	AvatarURL string `json:"avatar_url"`
}

type PostReportResponse struct {
	ID           uint          `json:"id"`
	PostID       uint          `json:"post_id"`
	TechnicianID uint          `json:"technician_id"`
	ReportType   string        `json:"report_type"`
	Reason       *string       `json:"reason"`
	Severity     string        `json:"severity"`
	DeletePost   bool          `json:"delete_post"`
	Admin        AdminResponse `json:"admin"`
	ReportedAt   int64         `json:"reported_at"`
}

type PostReportListResponse struct {
	Items   []PostReportResponse `json:"items"`
	Total   int64                `json:"total"`
	Page    int                  `json:"page"`
	PerPage int                  `json:"per_page"`
}

type ListPostReportsQuery struct {
	Page    int `query:"page"`
	PerPage int `query:"per_page"`
}

func (q *ListPostReportsQuery) SetDefaults() {
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PerPage < 1 || q.PerPage > 100 {
		q.PerPage = 20
	}
}
