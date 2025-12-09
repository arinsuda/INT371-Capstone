package technicianmatching

import (
	technician "changsure-core-service/internal/modules/technician"
)

func MapTechnicianToListItem(
	t *technician.Technician,
	dist float64,
) TechnicianListItem {

	min, max := ExtractPriceRange(*t)
	rating := ExtractRating(*t)

	badges := []string{}
	for _, b := range t.Badges {
		badges = append(badges, b.Badge.Name)
	}

	return TechnicianListItem{
		ID:          t.ID,
		FirstName:   t.FirstName,
		LastName:    t.LastName,
		AvatarURL:   t.AvatarURL,
		PriceMin:    min,
		PriceMax:    max,
		RatingAvg:   rating,
		RatingCount: t.RatingCount,
		DistanceKm:  dist,
		Badges:      badges,
	}
}

func MapTechnicianToDetail(t *technician.Technician) TechnicianDetail {

	rating := ExtractRating(*t)

	provinces := []string{}
	for _, a := range t.ServiceAreas {
		provinces = append(provinces, a.Province.NameTH)
	}

	badges := []string{}
	for _, b := range t.Badges {
		badges = append(badges, b.Badge.Name)
	}

	services := []string{}
	for _, s := range t.Services {
		services = append(services, s.Service.SerName)
	}

	return TechnicianDetail{
		ID:          t.ID,
		FirstName:   t.FirstName,
		LastName:    t.LastName,
		Bio:         t.Bio,
		AvatarURL:   t.AvatarURL,
		RatingAvg:   rating,
		RatingCount: t.RatingCount,
		TotalJobs:   t.TotalJobs,
		Provinces:   provinces,
		Badges:      badges,
		Services:    services,
	}
}
