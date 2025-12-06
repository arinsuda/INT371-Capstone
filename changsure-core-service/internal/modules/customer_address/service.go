package customeraddress

import (
	"context"
	"errors"

	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/pkg/utils"
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

func (s *service) checkOwnCustomer(ctx context.Context, customerID uint) error {
	requesterID := utils.GetUserIDFromContext(ctx)
	if requesterID == 0 {
		return addressshared.ErrUnauthorized
	}
	if requesterID != customerID {
		return addressshared.ErrUnauthorized
	}
	return nil
}

func (s *service) CreateCustomerAddress(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddress, error) {

	if err := s.checkOwnCustomer(ctx, customerID); err != nil {
		return nil, err
	}

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

	if err := s.checkOwnCustomer(ctx, customerID); err != nil {
		return nil, err
	}

	addr, err := s.repo.FindCustomerAddressByID(ctx, id, customerID)
	if err != nil {
		return nil, ErrNotFound
	}

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

	if err := s.checkOwnCustomer(ctx, customerID); err != nil {
		return err
	}

	return s.repo.DeleteCustomerAddress(ctx, id, customerID)
}

func (s *service) GetCustomerAddress(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error) {

	if err := s.checkOwnCustomer(ctx, customerID); err != nil {
		return nil, err
	}

	return s.repo.FindCustomerAddressByID(ctx, id, customerID)
}

func (s *service) ListCustomerAddresses(ctx context.Context, customerID uint) ([]*CustomerAddress, error) {

	if err := s.checkOwnCustomer(ctx, customerID); err != nil {
		return nil, err
	}

	return s.repo.FindCustomerAddresses(ctx, customerID)
}

func (s *service) SetPrimaryCustomerAddress(ctx context.Context, id uint, customerID uint) error {

	if err := s.checkOwnCustomer(ctx, customerID); err != nil {
		return err
	}

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
