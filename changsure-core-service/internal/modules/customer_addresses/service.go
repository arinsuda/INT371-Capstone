package customer_addresses

import (
	"context"
	"errors"

	"changsure-core-service/internal/modules/address_shared"
)

var ErrNotFound = errors.New("customer address not found")

type Service interface {
	Create(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddress, error)
	Update(ctx context.Context, id uint, customerID uint, req *UpdateCustomerAddressRequest) (*CustomerAddress, error)
	Delete(ctx context.Context, id uint, customerID uint) error
	Get(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error)
	List(ctx context.Context, customerID uint) ([]*CustomerAddress, error)
	SetPrimary(ctx context.Context, id uint, customerID uint) error

	NearbyTechnicians(ctx context.Context, q address_shared.NearbyQuery) ([]address_shared.NearbyTechnicianResult, error)
}

type service struct {
	repo       Repository
	techSearch TechnicianNearbySearcher
}

type TechnicianNearbySearcher interface {
	FindNearby(ctx context.Context, q address_shared.NearbyQuery) ([]address_shared.NearbyTechnicianResult, error)
}

func NewService(repo Repository, techSearch TechnicianNearbySearcher) Service {
	return &service{repo: repo, techSearch: techSearch}
}

func (s *service) Create(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddress, error) {
	addr := &CustomerAddress{
		CustomerID: customerID,
	}

	addr.HouseNumber = req.HouseNumber
	addr.Village = req.Village
	addr.Moo = req.Moo
	addr.Soi = req.Soi
	addr.Road = req.Road
	addr.SubDistrict = req.SubDistrict
	addr.District = req.District
	addr.Province = nil
	addr.PostalCode = req.PostalCode
	addr.Country = req.Country
	addr.ProvinceID = req.ProvinceID
	addr.Latitude = req.Latitude
	addr.Longitude = req.Longitude

	if req.IsPrimary != nil && *req.IsPrimary {
		_ = s.repo.ClearPrimary(ctx, customerID)
		addr.IsPrimary = true
	}

	if err := s.repo.Create(ctx, addr); err != nil {
		return nil, err
	}

	return addr, nil
}

func (s *service) Update(ctx context.Context, id uint, customerID uint, req *UpdateCustomerAddressRequest) (*CustomerAddress, error) {
	addr, err := s.repo.Get(ctx, id, customerID)
	if err != nil {
		return nil, ErrNotFound
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
			_ = s.repo.ClearPrimary(ctx, customerID)
		}
		addr.IsPrimary = *req.IsPrimary
	}

	if err := s.repo.Update(ctx, addr); err != nil {
		return nil, err
	}

	return addr, nil
}

func (s *service) Delete(ctx context.Context, id uint, customerID uint) error {
	return s.repo.Delete(ctx, id, customerID)
}

func (s *service) Get(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error) {
	return s.repo.Get(ctx, id, customerID)
}

func (s *service) List(ctx context.Context, customerID uint) ([]*CustomerAddress, error) {
	return s.repo.ListByCustomer(ctx, customerID)
}

func (s *service) SetPrimary(ctx context.Context, id uint, customerID uint) error {
	addr, err := s.repo.Get(ctx, id, customerID)
	if err != nil {
		return ErrNotFound
	}

	_ = s.repo.ClearPrimary(ctx, customerID)
	addr.IsPrimary = true

	return s.repo.Update(ctx, addr)
}

func (s *service) NearbyTechnicians(ctx context.Context, q address_shared.NearbyQuery) ([]address_shared.NearbyTechnicianResult, error) {
	return s.techSearch.FindNearby(ctx, q)
}
