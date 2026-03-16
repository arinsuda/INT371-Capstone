package technicianreview

type ListReviewsQuery struct {
	Page        int    `query:"page"`
	Limit       int    `query:"limit"`
	Rating      *int8  `query:"rating"`
	HasImages   string `query:"has_images"` 
	ServiceType *uint  `query:"service_type"`
}
