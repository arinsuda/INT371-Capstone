package servicecategory

import (
	"context"
)

type Service interface {
	List(ctx context.Context) ([]ServiceCategory, error)
	Get(ctx context.Context, id uint) (*ServiceCategory, error)
	UpdateImageURL(ctx context.Context, id uint, url string) error
}

type service struct{ repo Repository }

func NewService(repo Repository) Service { return &service{repo: repo} }

func (s *service) List(ctx context.Context) ([]ServiceCategory, error) { return s.repo.List(ctx) }
func (s *service) Get(ctx context.Context, id uint) (*ServiceCategory, error) {
	return s.repo.Get(ctx, id)
}
func (s *service) UpdateImageURL(ctx context.Context, id uint, url string) error {
	return s.repo.UpdateFields(ctx, id, map[string]any{"icon_url": url})
}
