package subdistrict

import (
	"context"
	"errors"
)

var ErrSubDistrictNotFound = errors.New("sub-district not found")

type Service interface {
	GetByID(ctx context.Context, id uint) (*SubDistrict, error)
	ListByDistrict(ctx context.Context, districtID uint) ([]*SubDistrict, error)
	ListFiltered(ctx context.Context, districtID, provinceID *uint, q string, limit int) ([]*SubDistrict, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) GetByID(ctx context.Context, id uint) (*SubDistrict, error) {
	return s.repo.GetByID(ctx, id)
}

func (s *service) ListByDistrict(ctx context.Context, districtID uint) ([]*SubDistrict, error) {
	return s.repo.GetByDistrictID(ctx, districtID)
}

func (s *service) ListFiltered(ctx context.Context, districtID, provinceID *uint, q string, limit int) ([]*SubDistrict, error) {
	if districtID != nil && q == "" {
		return s.repo.GetByDistrictID(ctx, *districtID)
	}
	if provinceID != nil && districtID == nil && q == "" {
		return s.repo.GetByProvinceID(ctx, *provinceID)
	}
	return s.repo.Search(ctx, districtID, provinceID, q, limit)
}
