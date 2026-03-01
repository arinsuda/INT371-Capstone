package technicianmatching

import (
	technician "changsure-core-service/internal/modules/technician"
	ts "changsure-core-service/internal/modules/technician_service"
)

func ExtractPriceRange(t technician.Technician, targetServiceID *uint) (float64, float64) {
	if len(t.Services) == 0 {
		return 0, 0
	}

	svc := findService(t.Services, targetServiceID)
	if svc == nil {
		return 0, 0
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

func findService(services []ts.TechnicianService, targetServiceID *uint) *ts.TechnicianService {
	if targetServiceID != nil {
		for i := range services {
			if services[i].Service.ID == *targetServiceID {
				return &services[i]
			}
		}
	}
	if len(services) > 0 {
		return &services[0]
	}
	return nil
}
