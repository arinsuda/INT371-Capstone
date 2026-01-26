package technicianmatching

import (
	"math"
)

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
		return 0, 0, 0, 0
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

		scorePrice := 0.0
		if maxPrice == minPrice {
			scorePrice = 1.0
		} else {
			scorePrice = (maxPrice - t.PriceMin) / (maxPrice - minPrice)
		}

		scoreDist := 0.0
		if maxDist == minDist {
			scoreDist = 1.0
		} else {
			scoreDist = (maxDist - t.DistanceKm) / (maxDist - minDist)
		}

		scoreRating := t.RatingAvg / 5.0
		if scoreRating > 1.0 {
			scoreRating = 1.0
		}

		totalScore := (w.Price * scorePrice) + (w.Distance * scoreDist) + (w.Rating * scoreRating)

		if len(t.Badges) > 0 {
			totalScore += 0.05
		}

		if totalScore > 1.0 {
			totalScore = 1.0
		}

		percentage := totalScore * 100
		t.MatchPercentage = math.Round(percentage*100) / 100
	}
	return list
}

func PickBestTechnician(list []TechnicianListItem) *TechnicianListItem {
	if len(list) == 0 {
		return nil
	}
	best := &list[0]
	for i := range list {
		if list[i].MatchPercentage > best.MatchPercentage {
			best = &list[i]
		}
	}
	return best
}
