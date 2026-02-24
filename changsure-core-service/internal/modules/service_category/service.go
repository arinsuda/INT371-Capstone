package servicecategory

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

var (
	ErrServiceCategoryNotFound = errors.New("service category not found")
)

type Service interface {
	ListServiceCategories(ctx context.Context) ([]ServiceCategory, error)
	GetServiceCategoryById(ctx context.Context, id uint) (*ServiceCategory, error)
	UpdateImageURL(ctx context.Context, id uint, url string) error
	UpdateFields(ctx context.Context, id uint, fields map[string]any) error
	CreateServiceCategory(ctx context.Context, sc *ServiceCategory) error
}

type service struct{ repo Repository }

func NewService(repo Repository) Service { return &service{repo: repo} }

func (s *service) ListServiceCategories(ctx context.Context) ([]ServiceCategory, error) {
	return s.repo.List(ctx)
}
func (s *service) GetServiceCategoryById(ctx context.Context, id uint) (*ServiceCategory, error) {
	return s.repo.Get(ctx, id)
}
func (s *service) UpdateImageURL(ctx context.Context, id uint, url string) error {
	return s.repo.UpdateFields(ctx, id, map[string]any{"icon_url": url})
}

func (s *service) UpdateFields(ctx context.Context, id uint, fields map[string]any) error {
	err := s.repo.UpdateFields(ctx, id, fields)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrServiceCategoryNotFound
		}
		return err
	}
	return nil
}

func (s *service) CreateServiceCategory(ctx context.Context, sc *ServiceCategory) error {
	return s.repo.Create(ctx, sc)
}
