package technicianmatching

func sortTechnicians(list []TechnicianListItem, sort string) []TechnicianListItem {

	switch sort {

	case "price_asc":
		SortBy(&list, func(a, b TechnicianListItem) bool {
			return a.PriceMin < b.PriceMin
		})

	case "price_desc":
		SortBy(&list, func(a, b TechnicianListItem) bool {
			return a.PriceMin > b.PriceMin
		})

	case "rating_asc":
		SortBy(&list, func(a, b TechnicianListItem) bool {
			return a.RatingAvg < b.RatingAvg
		})

	case "rating_desc":
		SortBy(&list, func(a, b TechnicianListItem) bool {
			return a.RatingAvg > b.RatingAvg
		})

	case "dist_asc":
		SortBy(&list, func(a, b TechnicianListItem) bool {
			return a.DistanceKm < b.DistanceKm
		})

	case "dist_desc":
		SortBy(&list, func(a, b TechnicianListItem) bool {
			return a.DistanceKm > b.DistanceKm
		})
	}

	return list
}
