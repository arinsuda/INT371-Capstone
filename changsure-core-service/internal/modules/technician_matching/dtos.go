package technicianmatching

type TechnicianSearchQuery struct {
	ServiceID  *uint    `query:"service_id"`
	ProvinceID *uint    `query:"province_id"`
	MinPrice   *float64 `query:"min_price"`
	MaxPrice   *float64 `query:"max_price"`
	MinRating  *float64 `query:"min_rating"`
	Sort       string   `query:"sort"`
	Page       int      `query:"page"`
	PageSize   int      `query:"page_size"`
}

func (q *TechnicianSearchQuery) SetDefaults() {
	if q.Page < 1 {
		q.Page = 1
	}
	if q.PageSize < 1 || q.PageSize > 100 {
		q.PageSize = 20
	}
}

type AutoSelectRequest struct {
	ServiceID  uint     `json:"service_id"  validate:"required,gt=0"`
	ProvinceID uint     `json:"province_id" validate:"required,gt=0"`
	Priority   string   `json:"priority"    validate:"omitempty,oneof=price distance rating balanced"`
	MinPrice   *float64 `json:"min_price"   validate:"omitempty,gte=0"`
	MaxPrice   *float64 `json:"max_price"   validate:"omitempty,gte=0"`
	MinRating  *float64 `json:"min_rating"  validate:"omitempty,gte=0,lte=5"`
}

type BadgeResponse struct {
	ID          uint   `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	IconURL     string `json:"icon_url"`
	Level       int    `json:"level"`
	IsActive    bool   `json:"is_active"`
	CreatedAt   int64  `json:"created_at"`
	UpdatedAt   int64  `json:"updated_at"`
}

type TechnicianListItem struct {
	ID              uint            `json:"id"`
	FirstName       string          `json:"firstname"`
	LastName        string          `json:"lastname"`
	AvatarURL       *string         `json:"avatar_url"`
	PriceMin        float64         `json:"price_min"`
	PriceMax        float64         `json:"price_max"`
	RatingAvg       float64         `json:"rating_avg"`
	RatingCount     int64            `json:"rating_count"`
	TotalJobs       int64            `json:"total_jobs"`
	DistanceKm      float64         `json:"distance_km"`
	ServiceID       uint            `json:"service_id"`
	CategoryName    string          `json:"category_name"`
	Badges          []BadgeResponse `json:"badges"`
	MatchPercentage float64         `json:"match_percentage"`
}

type TechnicianDetail struct {
	ID          uint            `json:"id"`
	FirstName   string          `json:"firstname"`
	LastName    string          `json:"lastname"`
	Bio         *string         `json:"bio"`
	AvatarURL   *string         `json:"avatar_url"`
	RatingAvg   float64         `json:"rating_avg"`
	RatingCount int64            `json:"rating_count"`
	TotalJobs   int64            `json:"total_jobs"`
	Provinces   []string        `json:"provinces"`
	Badges      []BadgeResponse `json:"badges"`
	Services    []string        `json:"services"`
	Categories  []string        `json:"categories"`
}

type PaginatedResponse[T any] struct {
	Items    []T   `json:"items"`
	Total    int64 `json:"total"`
	Page     int   `json:"page"`
	PageSize int   `json:"page_size"`
}
