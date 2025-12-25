package technicianmatching

import (
	technician "changsure-core-service/internal/modules/technician"
	"math"
)

func ExtractPriceRange(t technician.Technician) (float64, float64) {
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

func ExtractRating(t technician.Technician) float64 {
	if t.RatingAvg != nil {
		return *t.RatingAvg
	}
	return 0.0
}

func SelectBestTechnician(list []technician.Technician, priority string) *technician.Technician {
	if len(list) == 0 {
		return nil
	}

	best := list[0]

	for _, t := range list {
		switch priority {
		case "price":
			tMin, _ := ExtractPriceRange(t)
			bestMin, _ := ExtractPriceRange(best)
			if tMin < bestMin {
				best = t
			}

		case "rating":
			if ExtractRating(t) > ExtractRating(best) {
				best = t
			}

		case "balanced":
			tMin, _ := ExtractPriceRange(t)
			tScore := ExtractRating(t) / math.Log(tMin+2)

			bMin, _ := ExtractPriceRange(best)
			bScore := ExtractRating(best) / math.Log(bMin+2)

			if tScore > bScore {
				best = t
			}

		default:
			if ExtractRating(t) > ExtractRating(best) {
				best = t
			}
		}
	}

	return &best
}
