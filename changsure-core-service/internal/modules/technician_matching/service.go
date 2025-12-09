package technicianmatching

import (
	"context"
	"errors"
)

type Service interface {
	ListTechnicians(ctx context.Context, customerID uint, q TechnicianSearchQuery) ([]TechnicianListItem, int64, error)
	GetTechnicianDetail(ctx context.Context, id uint) (*TechnicianDetail, error)
	AutoSelectTechnician(ctx context.Context, customerID uint, req AutoSelectRequest) (*TechnicianListItem, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

// LIST
func (s *service) ListTechnicians(ctx context.Context, customerID uint, q TechnicianSearchQuery) ([]TechnicianListItem, int64, error) {

	custLat, custLng, err := s.repo.GetCustomerPrimaryAddress(ctx, customerID)
	if err != nil {
		return nil, 0, errors.New("customer has no primary address")
	}

	techs, err := s.repo.SearchTechnicians(ctx, q)
	if err != nil {
		return nil, 0, err
	}

	items := make([]TechnicianListItem, 0)

	for _, t := range techs {

		techLat, techLng, err := s.repo.GetTechnicianPrimaryAddress(ctx, t.ID)
		if err != nil {
			continue
		}

		dist := HaversineKm(custLat, custLng, techLat, techLng)

		item := MapTechnicianToListItem(&t, dist)

		if q.MinPrice != nil && item.PriceMin < *q.MinPrice {
			continue
		}
		if q.MaxPrice != nil && item.PriceMax > *q.MaxPrice {
			continue
		}
		if q.MinRating != nil && item.RatingAvg < *q.MinRating {
			continue
		}

		items = append(items, item)
	}

	total := int64(len(items))

	items = sortTechnicians(items, q.Sort)

	// pagination
	start := (q.Page - 1) * q.PageSize
	if start < 0 {
		start = 0
	}
	end := start + q.PageSize
	if end > len(items) {
		end = len(items)
	}

	if start >= len(items) {
		return []TechnicianListItem{}, total, nil
	}

	return items[start:end], total, nil
}

// DETAIL
func (s *service) GetTechnicianDetail(ctx context.Context, id uint) (*TechnicianDetail, error) {
	t, err := s.repo.FindByID(ctx, id)
	if err != nil {
		return nil, err
	}

	res := MapTechnicianToDetail(t)
	return &res, nil
}

// AUTO SELECT
func (s *service) AutoSelectTechnician(ctx context.Context, customerID uint, req AutoSelectRequest) (*TechnicianListItem, error) {
	q := TechnicianSearchQuery{
		ServiceID:  &req.ServiceID,
		ProvinceID: &req.ProvinceID,
		Page:       1,
		PageSize:   99999,
	}

	list, _, err := s.ListTechnicians(ctx, customerID, q)
	if err != nil {
		return nil, err
	}
	if len(list) == 0 {
		return nil, nil
	}

	best := pickBestTechnician(list, req.Priority)
	return best, nil
}
