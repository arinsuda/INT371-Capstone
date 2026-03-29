package technicianmatching

import (
	"context"
	"time"

	tb "changsure-core-service/internal/modules/technician_badge"
	"changsure-core-service/pkg/storage"
)

type Service interface {
	ListTechnicians(ctx context.Context, customerID uint, q TechnicianSearchQuery) (*PaginatedResponse[TechnicianListItem], error)
	AutoSelectTechnician(ctx context.Context, customerID uint, req AutoSelectRequest) (*TechnicianListItem, error)
}

type service struct {
	repo    Repository
	storage storage.Storage
}

func NewService(repo Repository, s storage.Storage) Service {
	return &service{repo: repo, storage: s}
}

func (s *service) ListTechnicians(
	ctx context.Context,
	customerID uint,
	q TechnicianSearchQuery,
) (*PaginatedResponse[TechnicianListItem], error) {

	custLat, custLng, err := s.repo.GetCustomerPrimaryAddress(ctx, customerID)
	if err != nil {
		return nil, ErrNoCustomerAddress
	}

	techsWithDist, total, err := s.repo.SearchTechnicians(ctx, custLat, custLng, q)
	if err != nil {
		return nil, err
	}

	items := make([]TechnicianListItem, 0, len(techsWithDist))
	for _, t := range techsWithDist {
		item := MapTechnicianToListItem(
			&t.Technician,
			t.DistanceMeters/1000.0,
			s.presignURL(ctx, t.AvatarURL),
			s.mapBadges(ctx, t.Badges),
			q.ServiceID,
		)
		items = append(items, item)
	}

	return &PaginatedResponse[TechnicianListItem]{
		Items:    items,
		Total:    total,
		Page:     q.Page,
		PageSize: q.PageSize,
	}, nil
}

func (s *service) AutoSelectTechnician(
	ctx context.Context,
	customerID uint,
	req AutoSelectRequest,
) (*TechnicianListItem, error) {

	q := TechnicianSearchQuery{
		ServiceID:  &req.ServiceID,
		ProvinceID: &req.ProvinceID,
		MinPrice:   req.MinPrice,
		MaxPrice:   req.MaxPrice,
		MinRating:  req.MinRating,
		Sort:       "random",
		Page:       1,
		PageSize:   100,
	}

	result, err := s.ListTechnicians(ctx, customerID, q)
	if err != nil {
		return nil, err
	}
	if len(result.Items) == 0 {
		return nil, ErrNoTechnicianFound
	}

	scored := CalculateMatchScore(result.Items, req.Priority)
	return PickBestTechnician(scored), nil
}

const presignTTL = 15 * time.Minute

func (s *service) presignURL(ctx context.Context, key *string) string {
	if key == nil || *key == "" {
		return ""
	}
	url, err := s.storage.PresignGet(ctx, *key, presignTTL, false)
	if err != nil {
		return ""
	}
	return url
}

func (s *service) mapBadges(ctx context.Context, rows []tb.TechnicianBadge) []BadgeResponse {
	list := make([]BadgeResponse, 0, len(rows))
	for _, b := range rows {
		list = append(list, BadgeResponse{
			ID:          b.Badge.ID,
			Name:        b.Badge.Name,
			Description: b.Badge.Description,
			IconURL:     s.presignURL(ctx, &b.Badge.IconURL),
			Level:       int(b.Badge.Level),
			IsActive:    b.Badge.IsActive,
			CreatedAt:   b.Badge.CreatedAt.Unix(),
			UpdatedAt:   b.Badge.UpdatedAt.Unix(),
		})
	}
	return list
}
