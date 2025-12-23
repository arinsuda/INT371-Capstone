package technicianmatching

type TechnicianSearchQuery struct {
	ServiceID  *uint `query:"service_id"`
	ProvinceID *uint `query:"province_id"`

	MinPrice  *float64 `query:"min_price"`
	MaxPrice  *float64 `query:"max_price"`
	MinRating *float64 `query:"min_rating"`

	Sort     string `query:"sort"`
	Page     int    `query:"page"`
	PageSize int    `query:"page_size"`
}

type AutoSelectRequest struct {
	ServiceID  uint   `json:"service_id"`
	ProvinceID uint   `json:"province_id"`
	Priority   string `json:"priority"`
}

type TechnicianListItem struct {
	ID        uint    `json:"id"`
	FirstName string  `json:"firstname"`
	LastName  string  `json:"lastname"`
	AvatarURL *string `json:"avatar_url"`

	PriceMin float64 `json:"price_min"`
	PriceMax float64 `json:"price_max"`

	RatingAvg   float64 `json:"rating_avg"`
	RatingCount uint    `json:"rating_count"`

	DistanceKm float64 `json:"distance_km"`

	Badges []BadgeResponse `json:"badges"`
}

type TechnicianDetail struct {
	ID          uint            `json:"id"`
	FirstName   string          `json:"firstname"`
	LastName    string          `json:"lastname"`
	Bio         *string         `json:"bio"`
	AvatarURL   *string         `json:"avatar_url"`
	RatingAvg   float64         `json:"rating_avg"`
	RatingCount uint            `json:"rating_count"`
	TotalJobs   uint            `json:"total_jobs"`
	Provinces   []string        `json:"provinces"`
	Badges      []BadgeResponse `json:"badges"`
	Services    []string        `json:"services"`
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
