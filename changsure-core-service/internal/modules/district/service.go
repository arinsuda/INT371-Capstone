package district

import "context"

type Service interface {
	ListByProvince(ctx context.Context, provinceID uint) ([]*District, error)
	ListFiltered(ctx context.Context, provinceID, subDistrictID *uint, q string, limit int) ([]*District, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) ListByProvince(ctx context.Context, provinceID uint) ([]*District, error) {
	return s.repo.GetByProvinceID(ctx, provinceID)
}

func (s *service) ListFiltered(
	ctx context.Context,
	provinceID,
	subDistrictID *uint,
	q string,
	limit int,
) ([]*District, error) {

	if subDistrictID != nil {
		return s.repo.GetBySubDistrictID(ctx, *subDistrictID)
	}

	return s.repo.Search(ctx, provinceID, q, limit)
}
