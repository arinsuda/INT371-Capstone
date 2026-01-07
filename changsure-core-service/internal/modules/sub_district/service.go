package subdistrict

import "context"

type Service interface {
	ListByDistrict(ctx context.Context, districtID uint) ([]*SubDistrict, error)
	ListFiltered(ctx context.Context, districtID, provinceID *uint, q string, limit int) ([]*SubDistrict, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
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
