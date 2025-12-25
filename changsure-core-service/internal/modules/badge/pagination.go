package badge

type Paginated[T any] struct {
	Items      []T   `json:"items"`
	Total      int64 `json:"total"`
	Page       int   `json:"page"`
	PerPage    int   `json:"per_page"`
	TotalPages int   `json:"total_pages"`
}

func normalizePage(page, perPage int) (int, int) {
	if page <= 0 {
		page = 1
	}
	if perPage <= 0 || perPage > 100 {
		perPage = 20
	}
	return page, perPage
}

func NewPaginated[T any](items []T, total int64, page, perPage int) Paginated[T] {
	if perPage <= 0 {
		perPage = 20
	}
	totalPages := int((total + int64(perPage) - 1) / int64(perPage))
	return Paginated[T]{
		Items:      items,
		Total:      total,
		Page:       page,
		PerPage:    perPage,
		TotalPages: totalPages,
	}
}
