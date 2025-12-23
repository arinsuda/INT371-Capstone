package technicianmatching

import (
	technician "changsure-core-service/internal/modules/technician"
)

func MapTechnicianToListItem(
	t *technician.Technician,
	dist float64,
	signedURL string,
	badges []BadgeResponse,
	targetServiceID *uint,
) TechnicianListItem {

	min, max := ExtractPriceRange(*t)
	rating := ExtractRating(*t)

	var avatarResult *string
	if signedURL != "" {
		avatarResult = &signedURL
	}

	var showServiceID uint
	var showCategoryName string

	if targetServiceID != nil {
		for _, s := range t.Services {
			if s.Service.ID == *targetServiceID {
				showServiceID = s.Service.ID
				if s.Service.Category != nil {
					showCategoryName = s.Service.Category.CatName
				}
				break
			}
		}
	}

	if showServiceID == 0 && len(t.Services) > 0 {
		firstSvc := t.Services[0]
		showServiceID = firstSvc.Service.ID
		if firstSvc.Service.Category != nil {
			showCategoryName = firstSvc.Service.Category.CatName
		}
	}

	return TechnicianListItem{
		ID:          t.ID,
		FirstName:   t.FirstName,
		LastName:    t.LastName,
		AvatarURL:   avatarResult,
		PriceMin:    min,
		PriceMax:    max,
		RatingAvg:   rating,
		RatingCount: t.RatingCount,
		TotalJobs:   t.TotalJobs,
		DistanceKm:  dist,

		ServiceID:    showServiceID,
		CategoryName: showCategoryName,

		Badges: badges,
	}
}

func MapTechnicianToDetail(t *technician.Technician, signedURL string, badges []BadgeResponse) TechnicianDetail {

	rating := ExtractRating(*t)

	provinces := []string{}
	for _, a := range t.ServiceAreas {
		provinces = append(provinces, a.Province.NameTH)
	}

	services := []string{}

	categoryMap := make(map[string]bool)

	for _, s := range t.Services {

		services = append(services, s.Service.SerName)

		if s.Service.Category != nil {
			categoryMap[s.Service.Category.CatName] = true
		}
	}

	categories := []string{}
	for catName := range categoryMap {
		categories = append(categories, catName)
	}

	var avatarResult *string
	if signedURL != "" {
		avatarResult = &signedURL
	}

	return TechnicianDetail{
		ID:          t.ID,
		FirstName:   t.FirstName,
		LastName:    t.LastName,
		Bio:         t.Bio,
		AvatarURL:   avatarResult,
		RatingAvg:   rating,
		RatingCount: t.RatingCount,
		TotalJobs:   t.TotalJobs,
		Provinces:   provinces,
		Categories:  categories,
		Services:    services,
		Badges:      badges,
	}
}
