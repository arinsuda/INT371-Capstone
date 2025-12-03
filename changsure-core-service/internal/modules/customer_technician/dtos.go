package customertechnician

type TechnicianListQuery struct {
	ServiceID  *uint
	ProvinceID *uint

	PriceSort    string
	RatingSort   string
	DistanceSort string

	Page     int
	PageSize int
}

type AutoSelectRequest struct {
	ServiceID  uint   `json:"service_id"`
	ProvinceID uint   `json:"province_id"`
	Priority   string `json:"priority"`
}

type TechnicianListItem struct {
	ID          uint     `json:"id"`
	FirstName   string   `json:"firstname"`
	LastName    string   `json:"lastname"`
	AvatarURL   *string  `json:"avatar_url"`
	Price       string   `json:"price"`
	RatingAvg   float64  `json:"rating_avg"`
	RatingCount uint     `json:"rating_count"`
	Badges      []string `json:"badges"`
}

type TechnicianDetail struct {
	ID          uint     `json:"id"`
	FirstName   string   `json:"firstname"`
	LastName    string   `json:"lastname"`
	Bio         *string  `json:"bio"`
	AvatarURL   *string  `json:"avatar_url"`
	RatingAvg   float64  `json:"rating_avg"`
	RatingCount uint     `json:"rating_count"`
	TotalJobs   uint     `json:"total_jobs"`
	Provinces   []string `json:"provinces"`
	Badges      []string `json:"badges"`
	Services    []string `json:"services"`
}
