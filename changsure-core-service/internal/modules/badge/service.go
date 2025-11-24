package badge

import (
	"context"
	"time"
)

type Service interface {
	Create(ctx context.Context, dto CreateBadgeDTO) (*Badge, error)
	Get(ctx context.Context, id uint, includeDeleted bool) (*Badge, error)
	Update(ctx context.Context, id uint, dto UpdateBadgeDTO) (*Badge, error)
	Delete(ctx context.Context, id uint) error
	Restore(ctx context.Context, id uint) error
	HardDelete(ctx context.Context, id uint) error
	List(ctx context.Context, q ListBadgesQuery) ([]Badge, int64, error)
}

type service struct{ repo Repository }

func NewService(repo Repository) Service { return &service{repo: repo} }

func (s *service) Create(ctx context.Context, dto CreateBadgeDTO) (*Badge, error) {
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
	if err := s.repo.Create(ctx, b); err != nil {
		return nil, err
	}
	return b, nil
}

func (s *service) Get(ctx context.Context, id uint, includeDeleted bool) (*Badge, error) {
	return s.repo.FindByID(ctx, id, includeDeleted)
}

func (s *service) Update(ctx context.Context, id uint, dto UpdateBadgeDTO) (*Badge, error) {
	b, err := s.repo.FindByID(ctx, id, true)
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
	if err := s.repo.Update(ctx, b); err != nil {
		return nil, err
	}
	return b, nil
}

func (s *service) Delete(ctx context.Context, id uint) error     { return s.repo.Delete(ctx, id) }
func (s *service) Restore(ctx context.Context, id uint) error    { return s.repo.Restore(ctx, id) }
func (s *service) HardDelete(ctx context.Context, id uint) error { return s.repo.HardDelete(ctx, id) }

func (s *service) List(ctx context.Context, q ListBadgesQuery) ([]Badge, int64, error) {
	return s.repo.List(ctx, q)
}
