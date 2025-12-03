package technicianaddress

import (
	"context"
	"errors"

	addressshared "changsure-core-service/internal/modules/address_shared"
)

var ErrAddressNotFound = errors.New("address not found")

type Service interface {
	Create(ctx context.Context, techID uint, req *CreateTechnicianAddressRequest) (*TechnicianAddress, error)
	Update(ctx context.Context, id uint, techID uint, req *UpdateTechnicianAddressRequest) (*TechnicianAddress, error)
	Delete(ctx context.Context, id uint, techID uint) error
	Get(ctx context.Context, id uint, techID uint) (*TechnicianAddress, error)
	List(ctx context.Context, techID uint) ([]*TechnicianAddress, error)
	SetPrimary(ctx context.Context, id uint, techID uint) error

	FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) Create(ctx context.Context, techID uint, req *CreateTechnicianAddressRequest) (*TechnicianAddress, error) {

	addr := &TechnicianAddress{
		TechnicianID: techID,
		AddressFields: addressshared.AddressFields{
			HouseNumber: req.HouseNumber,
			Village:     req.Village,
			Moo:         req.Moo,
			Soi:         req.Soi,
			Road:        req.Road,

			SubDistrict: req.SubDistrict,
			District:    req.District,
			Province:    req.Province,

			PostalCode: req.PostalCode,
			Country:    req.Country,

			ProvinceID: req.ProvinceID,
			Latitude:   req.Latitude,
			Longitude:  req.Longitude,

			IsPrimary: false,
		},
	}

	existing, _ := s.repo.ListByTechnician(ctx, techID)
	if len(existing) == 0 {
		addr.IsPrimary = true
	}

	if req.IsPrimary != nil && *req.IsPrimary {
		_ = s.repo.ClearPrimary(ctx, techID)
		addr.IsPrimary = true
	}

	if err := s.repo.Create(ctx, addr); err != nil {
		return nil, err
	}

	return addr, nil
}

func (s *service) Update(ctx context.Context, id uint, techID uint, req *UpdateTechnicianAddressRequest) (*TechnicianAddress, error) {

	addr, err := s.repo.Get(ctx, id, techID)
	if err != nil {
		return nil, ErrAddressNotFound
	}

	if req.HouseNumber != nil {
		addr.HouseNumber = req.HouseNumber
	}
	if req.Village != nil {
		addr.Village = req.Village
	}
	if req.Moo != nil {
		addr.Moo = req.Moo
	}
	if req.Soi != nil {
		addr.Soi = req.Soi
	}
	if req.Road != nil {
		addr.Road = req.Road
	}
	if req.SubDistrict != nil {
		addr.SubDistrict = req.SubDistrict
	}
	if req.District != nil {
		addr.District = req.District
	}
	if req.Province != nil {
		addr.Province = req.Province
	}
	if req.PostalCode != nil {
		addr.PostalCode = req.PostalCode
	}
	if req.Country != nil {
		addr.Country = req.Country
	}
	if req.ProvinceID != nil {
		addr.ProvinceID = req.ProvinceID
	}
	if req.Latitude != nil {
		addr.Latitude = req.Latitude
	}
	if req.Longitude != nil {
		addr.Longitude = req.Longitude
	}

	if req.IsPrimary != nil {
		if *req.IsPrimary {
			_ = s.repo.ClearPrimary(ctx, techID)
		}
		addr.IsPrimary = *req.IsPrimary
	}

	if err := s.repo.Update(ctx, addr); err != nil {
		return nil, err
	}

	return addr, nil
}

func (s *service) Delete(ctx context.Context, id uint, techID uint) error {
	return s.repo.Delete(ctx, id, techID)
}

func (s *service) Get(ctx context.Context, id uint, techID uint) (*TechnicianAddress, error) {
	return s.repo.Get(ctx, id, techID)
}

func (s *service) List(ctx context.Context, techID uint) ([]*TechnicianAddress, error) {
	return s.repo.ListByTechnician(ctx, techID)
}

func (s *service) SetPrimary(ctx context.Context, id uint, techID uint) error {
	addr, err := s.repo.Get(ctx, id, techID)
	if err != nil {
		return ErrAddressNotFound
	}

	_ = s.repo.ClearPrimary(ctx, techID)

	addr.IsPrimary = true

	return s.repo.Update(ctx, addr)
}

func (s *service) FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error) {
	return s.repo.FindNearby(ctx, q)
}
