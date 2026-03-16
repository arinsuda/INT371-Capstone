package customerreview

import (
	"context"
	"time"

	appErrors "changsure-core-service/internal/errors"
	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/pkg/utils"
)

type Service interface {
	CreateReview(ctx context.Context, customerID uint, bookingID uint, req CreateReviewRequest) (*booking.Review, error)
}

type service struct {
	repo booking.Repository
}

func NewService(repo booking.Repository) Service {
	return &service{repo: repo}
}

func (s *service) CreateReview(ctx context.Context, customerID uint, bookingID uint, req CreateReviewRequest) (*booking.Review, error) {
	b, err := s.repo.FindBookingForReview(ctx, bookingID, customerID)
	if err != nil {
		return nil, appErrors.NewInternal(err)
	}
	if b == nil {
		return nil, appErrors.NewNotFound("booking not found")
	}
	if b.Status != booking.BookingStatusCompleted {
		return nil, appErrors.NewConflict("booking is not completed yet")
	}
	if b.ReviewedAt != nil {
		return nil, appErrors.NewConflict("this booking has already been reviewed")
	}

	now := time.Now()
	review := &booking.Review{
		BookingID:  bookingID,
		CustomerID: customerID,
		ServiceID:  b.TechnicianService.ServiceID,
		Rating:     req.Rating,
		Comment:    req.Comment,
		CreatedAt:  now,
	}

	images := make([]booking.ReviewImage, 0, len(req.ImageURLs))
	for _, url := range req.ImageURLs {
		images = append(images, booking.ReviewImage{ImageURL: url})
	}

	if err := s.repo.CreateReview(ctx, review, images); err != nil {
		if utils.IsUniqueViolation(err) {
			return nil, appErrors.NewConflict("this booking has already been reviewed")
		}
		return nil, appErrors.NewInternal(err)
	}

	review.Images = images

	return review, nil
}
