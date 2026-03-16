package technicianreview

import (
	"context"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/modules/booking"
)

type Service interface {
	GetSummary(ctx context.Context, technicianID uint) (*booking.ReviewSummary, error)
	ListReviews(ctx context.Context, technicianID uint, q ListReviewsQuery) ([]booking.ReviewWithDetail, int64, error)
}

type service struct {
	repo booking.Repository
}

func NewService(repo booking.Repository) Service {
	return &service{repo: repo}
}

func (s *service) GetSummary(ctx context.Context, technicianID uint) (*booking.ReviewSummary, error) {
	summary, err := s.repo.GetTechnicianReviewSummary(ctx, technicianID)
	if err != nil {
		return nil, appErrors.NewInternal(err)
	}
	return summary, nil
}

func (s *service) ListReviews(ctx context.Context, technicianID uint, q ListReviewsQuery) ([]booking.ReviewWithDetail, int64, error) {
	if q.Page < 1 {
		q.Page = 1
	}
	if q.Limit < 1 || q.Limit > 50 {
		q.Limit = 10
	}

	filter := booking.ReviewFilter{
		Rating:      q.Rating,
		HasImages:   q.HasImages != nil && *q.HasImages,
		ServiceType: q.ServiceType,
	}

	reviews, total, err := s.repo.ListReviewsByTechnician(ctx, technicianID, filter, (q.Page-1)*q.Limit, q.Limit)
	if err != nil {
		return nil, 0, appErrors.NewInternal(err)
	}
	return reviews, total, nil
}
