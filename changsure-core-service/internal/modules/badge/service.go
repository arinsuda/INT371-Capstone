package badge

import (
	"context"
	"time"
)

type Service interface {
	CreateBadge(ctx context.Context, dto CreateBadgeDTO) (*Badge, error)
	UpdateBadge(ctx context.Context, id uint, dto UpdateBadgeDTO) (*Badge, error)
	SoftDeleteBadge(ctx context.Context, id uint) error
	RestoreBadge(ctx context.Context, id uint) error
	HardDeleteBadge(ctx context.Context, id uint) error
	ListBadges(ctx context.Context, q ListBadgesQuery) ([]Badge, int64, error)
	FindBadge(ctx context.Context, id uint, includeDeleted bool) (*Badge, error)
}

type service struct{ repo Repository }

func NewService(repo Repository) Service { return &service{repo: repo} }

func (s *service) CreateBadge(ctx context.Context, dto CreateBadgeDTO) (*Badge, error) {
	b := &Badge{
		Name: dto.Name,
		IconURL: func() string {
			if dto.IconURL == nil {
				return ""
			}
			return *dto.IconURL
		}(),
		Level: 0,
		IsActive: func() bool {
			if dto.IsActive == nil {
				return true
			}
			return *dto.IsActive
		}(),
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if dto.Level != nil {
		b.Level = *dto.Level
	}
	if dto.Description != nil {
		b.Description = *dto.Description
	}
	if err := s.repo.CreateBadge(ctx, b); err != nil {
		return nil, err
	}
	return b, nil
}

func (s *service) UpdateBadge(ctx context.Context, id uint, dto UpdateBadgeDTO) (*Badge, error) {
	b, err := s.repo.FindBadgeById(ctx, id, true)
	if err != nil {
		return nil, err
	}
	if dto.Name != nil {
		b.Name = *dto.Name
	}
	if dto.IconURL != nil {
		b.IconURL = *dto.IconURL
	}
	if dto.Level != nil {
		b.Level = *dto.Level
	}
	if dto.IsActive != nil {
		b.IsActive = *dto.IsActive
	}
	if dto.Description != nil {
		b.Description = *dto.Description
	}
	b.UpdatedAt = time.Now()
	if err := s.repo.UpdateBadge(ctx, b); err != nil {
		return nil, err
	}
	return b, nil
}

func (s *service) SoftDeleteBadge(ctx context.Context, id uint) error { return s.repo.SoftDelete(ctx, id) }
func (s *service) RestoreBadge(ctx context.Context, id uint) error    { return s.repo.RestoreBadge(ctx, id) }
func (s *service) HardDeleteBadge(ctx context.Context, id uint) error {
	return s.repo.HardDelete(ctx, id)
}

func (s *service) ListBadges(ctx context.Context, q ListBadgesQuery) ([]Badge, int64, error) {
	return s.repo.ListBadges(ctx, q)
}

func (s *service) FindBadge(ctx context.Context, id uint, includeDeleted bool) (*Badge, error) {
	return s.repo.FindBadgeById(ctx, id, includeDeleted)
}
