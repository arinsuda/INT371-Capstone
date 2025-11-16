package technician_badges

import (
	"context"
	"time"
)

type Service interface {
	AssignBadge(ctx context.Context, technicianID, badgeID uint, expiredAt *time.Time) (*TechnicianBadge, error)
	GetBadgesByTechnician(ctx context.Context, technicianID uint) ([]TechnicianBadge, error)
	RemoveBadge(ctx context.Context, id uint, hard bool) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) AssignBadge(ctx context.Context, technicianID, badgeID uint, expiredAt *time.Time) (*TechnicianBadge, error) {
	tb := &TechnicianBadge{
		TechnicianID: technicianID,
		BadgeID:      badgeID,
	}
	if err := s.repo.Create(ctx, tb); err != nil {
		return nil, err
	}
	return tb, nil
}

func (s *service) GetBadgesByTechnician(ctx context.Context, technicianID uint) ([]TechnicianBadge, error) {
	return s.repo.FindByTechnician(ctx, technicianID)
}

func (s *service) RemoveBadge(ctx context.Context, id uint, hard bool) error {
	if hard {
		return s.repo.HardDeleteByID(ctx, id)
	}
	return s.repo.DeleteByID(ctx, id)
}
