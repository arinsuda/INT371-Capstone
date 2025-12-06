package customeraddress

import (
	"context"
	"errors"

	addressshared "changsure-core-service/internal/modules/address_shared"
)

var ErrNotFound = errors.New("customer address not found")

type Service interface {
	CreateCustomerAddress(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddress, error)
	UpdateCustomerAddress(ctx context.Context, id uint, customerID uint, req *UpdateCustomerAddressRequest) (*CustomerAddress, error)
	DeleteCustomerAddress(ctx context.Context, id uint, customerID uint) error
	GetCustomerAddress(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error)
	ListCustomerAddresses(ctx context.Context, customerID uint) ([]*CustomerAddress, error)
	SetPrimaryCustomerAddress(ctx context.Context, id uint, customerID uint) error

	SearchNearbyTechnicians(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error)
}

type service struct {
	repo       Repository
	techSearch TechnicianNearbySearcher
}

type TechnicianNearbySearcher interface {
	FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error)
}

func NewService(repo Repository, techSearch TechnicianNearbySearcher) Service {
	return &service{repo: repo, techSearch: techSearch}
}

func (s *service) CreateCustomerAddress(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddress, error) {
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
		_ = s.repo.SetPrimaryCustomerAddress(ctx, customerID)
		addr.IsPrimary = true
	}

	if err := s.repo.CreateCustomerAddress(ctx, addr); err != nil {
		return nil, err
	}

	return addr, nil
}

func (s *service) UpdateCustomerAddress(
	ctx context.Context,
	id uint,
	customerID uint,
	req *UpdateCustomerAddressRequest,
) (*CustomerAddress, error) {

	addr, err := s.repo.FindCustomerAddressByID(ctx, id, customerID)
	if err != nil {
		return nil, ErrNotFound
	}

	// FULL REPLACE — เหมือน PUT ควรทำ
	addr.HouseNumber = &req.HouseNumber
	addr.Village = &req.Village
	addr.Moo = &req.Moo
	addr.Soi = &req.Soi
	addr.Road = &req.Road

	addr.SubDistrict = &req.SubDistrict
	addr.District = &req.District
	addr.Province = &req.Province

	addr.PostalCode = &req.PostalCode
	addr.Country = &req.Country

	addr.ProvinceID = &req.ProvinceID
	addr.Latitude = &req.Latitude
	addr.Longitude = &req.Longitude

	// HANDLE PRIMARY FLAG
	if req.IsPrimary {
		_ = s.repo.SetPrimaryCustomerAddress(ctx, customerID)
	}
	addr.IsPrimary = req.IsPrimary

	if err := s.repo.UpdateCustomerAddress(ctx, addr); err != nil {
		return nil, err
	}

	return addr, nil
}

func (s *service) DeleteCustomerAddress(ctx context.Context, id uint, customerID uint) error {
	return s.repo.DeleteCustomerAddress(ctx, id, customerID)
}

func (s *service) GetCustomerAddress(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error) {
	return s.repo.FindCustomerAddressByID(ctx, id, customerID)
}

func (s *service) ListCustomerAddresses(ctx context.Context, customerID uint) ([]*CustomerAddress, error) {
	return s.repo.FindCustomerAddresses(ctx, customerID)
}

func (s *service) SetPrimaryCustomerAddress(ctx context.Context, id uint, customerID uint) error {
	addr, err := s.repo.FindCustomerAddressByID(ctx, id, customerID)
	if err != nil {
		return ErrNotFound
	}

	_ = s.repo.SetPrimaryCustomerAddress(ctx, customerID)
	addr.IsPrimary = true

	return s.repo.UpdateCustomerAddress(ctx, addr)
}

func (s *service) SearchNearbyTechnicians(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error) {
	return s.techSearch.FindNearby(ctx, q)
}
