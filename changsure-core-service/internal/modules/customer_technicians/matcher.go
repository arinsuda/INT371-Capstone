package customer_technicians

import (
	technicians "changsure-core-service/internal/modules/technicians"
	"fmt"
)

func extractPrice(t technicians.Technician) (min float64, max float64) {
	if len(t.Services) == 0 {
		return 0, 0
	}

	svc := t.Services[0]

	switch svc.PricingType {
	case "FIXED":
		if svc.PriceFixed != nil {
			return *svc.PriceFixed, *svc.PriceFixed
		}
	case "RANGE":
		if svc.PriceMin != nil && svc.PriceMax != nil {
			return *svc.PriceMin, *svc.PriceMax
		}
	}

	return 0, 0
}

func extractRating(t technicians.Technician) float64 {
	if t.RatingAvg != nil {
		return *t.RatingAvg
	}
	return 0.0
}

func pickBestTechnician(list []technicians.Technician, priority string) *technicians.Technician {
	if len(list) == 0 {
		return nil
	}

	best := list[0]

	for _, t := range list {
		switch priority {

		case "price":
			tMin, _ := extractPrice(t)
			bestMin, _ := extractPrice(best)

			if tMin < bestMin {
				best = t
			}

		case "rating":
			tRating := extractRating(t)
			bestRating := extractRating(best)

			if tRating > bestRating {
				best = t
			}

		case "balanced":
			tMin, _ := extractPrice(t)
			tRating := extractRating(t)

			bMin, _ := extractPrice(best)
			bRating := extractRating(best)

			tScore := tRating / logPrice(tMin)
			bScore := bRating / logPrice(bMin)

			if tScore > bScore {
				best = t
			}

		default:
			if extractRating(t) > extractRating(best) {
				best = t
			}
		}
	}

	return &best
}

func logPrice(p float64) float64 {

	if p < 1 {
		p = 1
	}

	return 1 + (p / 500.0)
}

func toListItem(t *technicians.Technician) TechnicianListItem {
	rating := extractRating(*t)
	min, _ := extractPrice(*t)

	priceStr := fmt.Sprintf("฿%.0f", min)

	badges := make([]string, 0)
	for _, b := range t.Badges {
		badges = append(badges, b.Badge.Name)
	}

	return TechnicianListItem{
		ID:          t.ID,
		FirstName:   t.FirstName,
		LastName:    t.LastName,
		AvatarURL:   t.AvatarURL,
		Price:       priceStr,
		RatingAvg:   rating,
		RatingCount: t.RatingCount,
		Badges:      badges,
	}
}
