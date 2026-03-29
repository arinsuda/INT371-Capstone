package dashboard

import "time"

type SummaryCards struct {
	TotalTechnicians    int64 `json:"total_technicians"`
	PendingVerification int64 `json:"pending_verification"`
	ReportedTechnicians int64 `json:"reported_technicians"`
}

type CategoryStat struct {
	CategoryID   uint    `json:"category_id"`
	CategoryName string  `json:"category_name"`
	Count        int64   `json:"count"`
	Percentage   float64 `json:"percentage"`
}

type PostWarningSummary struct {
	Normal int64 `json:"normal"`
	Warned int64 `json:"warned"`
	Banned int64 `json:"banned"`
}

type RegistrationDay struct {
	Date    string `json:"date"`
	DayName string `json:"day_name"`
	Passed  int64  `json:"passed"`
	Pending int64  `json:"pending"`
	Failed  int64  `json:"failed"`
	Total   int64  `json:"total"`
}

type PendingVerificationItem struct {
	TechnicianID uint      `json:"technician_id"`
	FirstName    string    `json:"firstname"`
	LastName     string    `json:"lastname"`
	Email        *string   `json:"email,omitempty"`
	RegisteredAt time.Time `json:"registered_at"`
	PendingCount int64     `json:"pending_count"`
}

type PendingVerificationResponse struct {
	Items    []PendingVerificationItem `json:"items"`
	Total    int64                     `json:"total"`
	Page     int                       `json:"page"`
	PageSize int                       `json:"page_size"`
}

type DashboardResponse struct {
	Summary           SummaryCards       `json:"summary"`
	CategoryStats     []CategoryStat     `json:"category_stats"`
	PostWarning       PostWarningSummary `json:"post_warning"`
	Registrations     []RegistrationDay  `json:"registrations"`
	RegistrationRange string             `json:"registration_range"`
}

type ServiceInCategoryItem struct {
	ServiceID   uint   `json:"service_id"`
	ServiceName string `json:"service_name"`
	TechCount   int64  `json:"tech_count"`
}

type CategoryServiceResponse struct {
	CategoryID   uint                    `json:"category_id"`
	CategoryName string                  `json:"category_name"`
	Services     []ServiceInCategoryItem `json:"services"`
}

type TechnicianInServiceItem struct {
	TechnicianID uint    `json:"technician_id"`
	FirstName    string  `json:"firstname"`
	LastName     string  `json:"lastname"`
	AvatarURL    *string `json:"avatar_url,omitempty"`
	RatingAvg    float64 `json:"rating_avg"`
	TotalJobs    int64   `json:"total_jobs"`
	IsAvailable  bool    `json:"is_available"`
}

type ServiceTechnicianResponse struct {
	ServiceID   uint                      `json:"service_id"`
	ServiceName string                    `json:"service_name"`
	Items       []TechnicianInServiceItem `json:"items"`
	Total       int64                     `json:"total"`
	Page        int                       `json:"page"`
	PageSize    int                       `json:"page_size"`
}

type DashboardQuery struct {
	Range string `query:"range"`
}

func (q *DashboardQuery) Days() int {
	switch q.Range {
	case "30d":
		return 30
	case "90d":
		return 90
	default:
		return 7
	}
}

func (q *DashboardQuery) SetDefaults() {
	if q.Range == "" {
		q.Range = "7d"
	}
}

type ServiceTechQuery struct {
	Page     int `query:"page"`
	PageSize int `query:"page_size"`
}

func (q *ServiceTechQuery) SetDefaults() {
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 || q.PageSize > 100 {
		q.PageSize = 20
	}
}

type PendingVerificationQuery struct {
	Page     int `query:"page"`
	PageSize int `query:"page_size"`
}

type ActionItem struct {
	Type      string `json:"type"`
	Title     string `json:"title"`
	ActionURL string `json:"action_url"`
	Date      string `json:"date,omitempty"`
}

type PendingOverview struct {
	Date  string `json:"date"  gorm:"column:date"`
	Count int64  `json:"count" gorm:"column:count"`
}

func (q *PendingVerificationQuery) SetDefaults() {
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 || q.PageSize > 100 {
		q.PageSize = 10
	}
}
