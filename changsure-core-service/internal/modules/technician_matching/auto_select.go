package technicianmatching

import "math"

type Weights struct {
	Price    float64
	Distance float64
	Rating   float64
}

func getWeights(priority string) Weights {
	switch priority {
	case "price":
		return Weights{Price: 0.60, Distance: 0.20, Rating: 0.20}
	case "distance":
		return Weights{Price: 0.20, Distance: 0.60, Rating: 0.20}
	case "rating":
		return Weights{Price: 0.20, Distance: 0.20, Rating: 0.60}
	case "balanced":
		return Weights{Price: 0.40, Distance: 0.30, Rating: 0.30}
	default:
		return Weights{Price: 0.35, Distance: 0.30, Rating: 0.35}
	}
}

func findMinMax(list []TechnicianListItem) (minP, maxP, minD, maxD float64) {
	if len(list) == 0 {
		return
	}
	minP, maxP = list[0].PriceMin, list[0].PriceMin
	minD, maxD = list[0].DistanceKm, list[0].DistanceKm
	for _, t := range list {
		if t.PriceMin < minP {
			minP = t.PriceMin
		}
		if t.PriceMin > maxP {
			maxP = t.PriceMin
		}
		if t.DistanceKm < minD {
			minD = t.DistanceKm
		}
		if t.DistanceKm > maxD {
			maxD = t.DistanceKm
		}
	}
	return
}

func CalculateMatchScore(list []TechnicianListItem, priority string) []TechnicianListItem {
	if len(list) == 0 {
		return list
	}

	minPrice, maxPrice, minDist, maxDist := findMinMax(list)
	w := getWeights(priority)

	for i := range list {
		t := &list[i]

		scorePrice := normaliseInverse(t.PriceMin, minPrice, maxPrice)
		scoreDist := normaliseInverse(t.DistanceKm, minDist, maxDist)
		scoreRating := clamp(t.RatingAvg/5.0, 0, 1)

		total := w.Price*scorePrice + w.Distance*scoreDist + w.Rating*scoreRating
		if len(t.Badges) > 0 {
			total += 0.05
		}

		t.MatchPercentage = math.Round(clamp(total, 0, 1)*100*100) / 100
	}
	return list
}

func PickBestTechnician(list []TechnicianListItem) *TechnicianListItem {
	if len(list) == 0 {
		return nil
	}
	best := &list[0]
	for i := range list[1:] {
		if list[i+1].MatchPercentage > best.MatchPercentage {
			best = &list[i+1]
		}
	}
	return best
}

func normaliseInverse(value, min, max float64) float64 {
	if max == min {
		return 1.0
	}
	return (max - value) / (max - min)
}

func clamp(v, lo, hi float64) float64 {
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}
