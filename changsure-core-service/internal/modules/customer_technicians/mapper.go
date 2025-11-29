package customer_technicians

import (
	technicians "changsure-core-service/internal/modules/technicians"
	"fmt"
)

func mapToListItem(t *technicians.Technician) TechnicianListItem {
	rating := 0.0
	if t.RatingAvg != nil {
		rating = *t.RatingAvg
	}

	price := "฿0"
	if len(t.Services) > 0 {
		svc := t.Services[0]
		switch svc.PricingType {
		case "FIXED":
			if svc.PriceFixed != nil {
				price = fmt.Sprintf("฿%.0f", *svc.PriceFixed)
			}
		case "RANGE":
			if svc.PriceMin != nil {
				price = fmt.Sprintf("฿%.0f+", *svc.PriceMin)
			}
		}
	}

	badges := make([]string, 0)
	for _, b := range t.Badges {
		badges = append(badges, b.Badge.Name)
	}

	return TechnicianListItem{
		ID:          t.ID,
		FirstName:   t.FirstName,
		LastName:    t.LastName,
		AvatarURL:   t.AvatarURL,
		Price:       price,
		RatingAvg:   rating,
		RatingCount: t.RatingCount,
		Badges:      badges,
	}
}

func mapToDetail(t *technicians.Technician) TechnicianDetail {
	rating := 0.0
	if t.RatingAvg != nil {
		rating = *t.RatingAvg
	}

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
