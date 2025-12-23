package technicianmatching

import (
	technician "changsure-core-service/internal/modules/technician"
)

func MapTechnicianToListItem(
	t *technician.Technician,
	dist float64,
	signedURL string,
	badges []BadgeResponse,
) TechnicianListItem {

	min, max := ExtractPriceRange(*t)
	rating := ExtractRating(*t)

	var avatarResult *string
	if signedURL != "" {
		avatarResult = &signedURL
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
		DistanceKm:  dist,
		Badges:      badges,
	}
}

func MapTechnicianToDetail(t *technician.Technician, signedURL string, badges []BadgeResponse) TechnicianDetail {

	rating := ExtractRating(*t)

	provinces := []string{}
	for _, a := range t.ServiceAreas {
		provinces = append(provinces, a.Province.NameTH)
	}

	services := []string{}
	for _, s := range t.Services {
		services = append(services, s.Service.SerName)
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
		Badges:      badges,
		Services:    services,
	}
}
