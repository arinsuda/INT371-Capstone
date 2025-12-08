package technicianmatching

import "math"

func pickBestTechnician(list []TechnicianListItem, prio string) *TechnicianListItem {

	if len(list) == 0 {
		return nil
	}

	best := list[0]

	for _, t := range list {

		switch prio {

		case "price":
			if t.PriceMin < best.PriceMin {
				best = t
			}

		case "rating":
			if t.RatingAvg > best.RatingAvg {
				best = t
			}

		case "distance":
			if t.DistanceKm < best.DistanceKm {
				best = t
			}

		case "balanced":
			scoreT := t.RatingAvg / math.Log(t.PriceMin+2)
			scoreB := best.RatingAvg / math.Log(best.PriceMin+2)

			if scoreT > scoreB {
				best = t
			}

		default:
			if t.RatingAvg > best.RatingAvg {
				best = t
			}
		}
	}

	return &best
}
