package technicianmatching

import "math"

func HaversineKm(lat1, lon1, lat2, lon2 float64) float64 {
	R := 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180
	dLon := (lon2 - lon1) * math.Pi / 180
	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Cos(lat1*math.Pi/180)*math.Cos(lat2*math.Pi/180)*
			math.Sin(dLon/2)*math.Sin(dLon/2)

	return R * 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
}

func SortBy[T any](items *[]T, less func(T, T) bool) {
	list := *items
	for i := 0; i < len(list); i++ {
		for j := i + 1; j < len(list); j++ {
			if less(list[j], list[i]) {
				list[i], list[j] = list[j], list[i]
			}
		}
	}
}
