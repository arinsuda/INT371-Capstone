package technicianbadge

import (
	"context"
	"errors"
	"time"
)

var (
	ErrBadgeAlreadyAssigned = errors.New("technician already has this badge")
	ErrTechnicianNotFound   = errors.New("technician not found")
	ErrBadgeNotAssigned     = errors.New("badge not assigned to technician")
)

type TechnicianReader interface {
	ExistsByID(ctx context.Context, id uint) (bool, error)
}

type Service interface {
	AssignBadge(ctx context.Context, techID, badgeID uint, expiredAt *time.Time) (*TechnicianBadge, error)
	GetBadgesByTechnician(ctx context.Context, techID uint) ([]TechnicianBadge, error)
	RemoveBadge(ctx context.Context, techID, badgeID uint) error
}

type service struct {
	repo     Repository
	techRepo TechnicianReader
}

func NewService(repo Repository, techRepo TechnicianReader) Service {
	return &service{repo: repo, techRepo: techRepo}
}

func (s *service) ensureTechExists(ctx context.Context, id uint) error {
	ok, err := s.techRepo.ExistsByID(ctx, id)
	if err != nil {
		return err
	}
	if !ok {
		return ErrTechnicianNotFound
	}
	return nil
}

func (s *service) AssignBadge(ctx context.Context, techID, badgeID uint, exp *time.Time) (*TechnicianBadge, error) {
	if err := s.ensureTechExists(ctx, techID); err != nil {
		return nil, err
	}

	exists, err := s.repo.CheckBadgeExists(ctx, techID, badgeID)
	if err != nil {
		return nil, err
	}
	if exists {
		return nil, ErrBadgeAlreadyAssigned
	}

	tb := &TechnicianBadge{
		TechnicianID: techID,
		BadgeID:      badgeID,
	}

	if err := s.repo.Create(ctx, tb); err != nil {
		return nil, err
	}

	_ = s.repo.PreloadBadge(ctx, tb)
	return tb, nil
}

func (s *service) GetBadgesByTechnician(ctx context.Context, techID uint) ([]TechnicianBadge, error) {
	if err := s.ensureTechExists(ctx, techID); err != nil {
		return nil, err
	}
	return s.repo.FindByTechnician(ctx, techID)
}

func (s *service) RemoveBadge(ctx context.Context, techID, badgeID uint) error {
	if err := s.ensureTechExists(ctx, techID); err != nil {
		return err
	}

	exists, err := s.repo.CheckBadgeExists(ctx, techID, badgeID)
	if err != nil {
		return err
	}
	if !exists {
		return ErrBadgeNotAssigned
	}

	return s.repo.DeleteByTechAndBadge(ctx, techID, badgeID)
}
