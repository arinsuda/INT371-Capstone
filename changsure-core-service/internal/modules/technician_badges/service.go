// internal/modules/technician_badges/service.go
package technician_badges

import (
	"context"
	"errors"
	"time"
)

var ErrTechnicianNotFound = errors.New("technician not found")

type Service interface {
	AssignBadge(ctx context.Context, technicianID, badgeID uint, expiredAt *time.Time) (*TechnicianBadge, error)
	GetBadgesByTechnician(ctx context.Context, technicianID uint) ([]TechnicianBadge, error)
	RemoveBadge(ctx context.Context, id uint, hard bool) error
}

type TechnicianReader interface {
	ExistsByID(ctx context.Context, id uint) (bool, error)
}

type service struct {
	repo     Repository
	techRepo TechnicianReader
}

func NewService(repo Repository, techRepo TechnicianReader) Service {
	return &service{repo: repo, techRepo: techRepo}
}

func (s *service) ensureTechExists(ctx context.Context, technicianID uint) error {
	ok, err := s.techRepo.ExistsByID(ctx, technicianID)
	if err != nil {
		return err
	}
	if !ok {
		return ErrTechnicianNotFound
	}
	return nil
}

func (s *service) AssignBadge(ctx context.Context, technicianID, badgeID uint, expiredAt *time.Time) (*TechnicianBadge, error) {
	if err := s.ensureTechExists(ctx, technicianID); err != nil {
		return nil, err
	}

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
	if err := s.ensureTechExists(ctx, technicianID); err != nil {
		return nil, err
	}
	return s.repo.FindByTechnician(ctx, technicianID)
}

func (s *service) RemoveBadge(ctx context.Context, id uint, hard bool) error {
	if hard {
		return s.repo.HardDeleteByID(ctx, id)
	}
	return s.repo.DeleteByID(ctx, id)
}
