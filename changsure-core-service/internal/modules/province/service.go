package province

import (
	"context"
	"errors"
	"fmt"
)

var (
	ErrProvinceNotFound = errors.New("province not found")
	ErrInvalidInput     = errors.New("invalid input")
)

type Service interface {
	CreateProvince(ctx context.Context, req *CreateProvinceRequest) (*Province, error)
	GetProvince(ctx context.Context, id uint) (*Province, error)
	UpdateProvince(ctx context.Context, id uint, req *UpdateProvinceRequest) (*Province, error)
	DeleteProvince(ctx context.Context, id uint) error
	ListProvinces(ctx context.Context) ([]*Province, error)
	CountProvinces(ctx context.Context) (int64, error)

	ListProvincesFiltered(ctx context.Context, districtID, subDistrictID *uint, q string, limit int) ([]*Province, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) CreateProvince(ctx context.Context, req *CreateProvinceRequest) (*Province, error) {
	if req == nil {
		return nil, fmt.Errorf("%w: empty request", ErrInvalidInput)
	}
	if err := req.Validate(); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidInput, err)
	}
	p := &Province{NameTH: req.NameTH}
	if err := s.repo.Create(ctx, p); err != nil {
		return nil, err
	}
	return p, nil
}

func (s *service) GetProvince(ctx context.Context, id uint) (*Province, error) {
	p, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, ErrProvinceNotFound
	}
	return p, nil
}

func (s *service) UpdateProvince(ctx context.Context, id uint, req *UpdateProvinceRequest) (*Province, error) {
	if req == nil {
		return nil, fmt.Errorf("%w: empty request", ErrInvalidInput)
	}
	if err := req.Validate(); err != nil {
		return nil, fmt.Errorf("%w: %v", ErrInvalidInput, err)
	}
	p, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, ErrProvinceNotFound
	}
	if req.NameTH != nil {
		p.NameTH = *req.NameTH
	}
	if err := s.repo.Update(ctx, p); err != nil {
		return nil, err
	}
	return p, nil
}

func (s *service) DeleteProvince(ctx context.Context, id uint) error {
	p, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if p == nil {
		return ErrProvinceNotFound
	}
	return s.repo.Delete(ctx, id)
}

func (s *service) ListProvinces(ctx context.Context) ([]*Province, error) {
	return s.repo.GetAll(ctx)
}

func (s *service) CountProvinces(ctx context.Context) (int64, error) {
	return s.repo.Count(ctx)
}

func (s *service) ListProvincesFiltered(ctx context.Context, districtID, subDistrictID *uint, q string, limit int) ([]*Province, error) {
	if subDistrictID != nil {
		return s.repo.GetBySubDistrictID(ctx, *subDistrictID)
	}
	if districtID != nil {
		return s.repo.GetByDistrictID(ctx, *districtID)
	}
	if q != "" {
		return s.repo.Search(ctx, q, limit)
	}
	return s.repo.GetAll(ctx)
}
