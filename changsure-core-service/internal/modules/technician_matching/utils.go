package technicianmatching

import (
	technician "changsure-core-service/internal/modules/technician"
	ts "changsure-core-service/internal/modules/technician_service"
	"math"
)

func ExtractPriceRange(t technician.Technician, targetServiceID *uint) (float64, float64) {

	if len(t.Services) == 0 {
		return 0, 0
	}

	var svc *ts.TechnicianService

	if targetServiceID != nil {
		for i := range t.Services {
			if t.Services[i].Service.ID == *targetServiceID {
				svc = &t.Services[i]
				break
			}
		}
	}

	// fallback → first service
	if svc == nil {
		svc = &t.Services[0]
	}

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

func SelectBestTechnician(
	list []technician.Technician,
	priority string,
	serviceID *uint,
) *technician.Technician {

	if len(list) == 0 {
		return nil
	}

	bestIndex := 0

	for i := 1; i < len(list); i++ {

		current := list[i]
		best := list[bestIndex]

		switch priority {

		case "price":

			curMin, _ := ExtractPriceRange(current, serviceID)
			bestMin, _ := ExtractPriceRange(best, serviceID)

			if curMin < bestMin {
				bestIndex = i
			}

		case "rating":

			if ExtractRating(current) > ExtractRating(best) {
				bestIndex = i
			}

		case "balanced":

			curMin, _ := ExtractPriceRange(current, serviceID)
			bestMin, _ := ExtractPriceRange(best, serviceID)

			curScore := ExtractRating(current) / math.Log(curMin+2)
			bestScore := ExtractRating(best) / math.Log(bestMin+2)

			if curScore > bestScore {
				bestIndex = i
			}

		default:

			if ExtractRating(current) > ExtractRating(best) {
				bestIndex = i
			}
		}
	}

	return &list[bestIndex]
}
