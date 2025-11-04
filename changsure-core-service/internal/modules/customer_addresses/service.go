package customeraddresses

import (
	"context"
	"errors"
	"fmt"
	"log"

	"changsure-core-service/internal/validation"
)

var (
	ErrAddressNotFound = errors.New("address not found")
	ErrInvalidInput    = errors.New("invalid input")
	ErrCustomerMissing = errors.New("customer not found")
)

type CustomerChecker interface {
	Exists(ctx context.Context, id uint) (bool, error)
}

type Service interface {
	CreateAddress(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddress, error)
	GetAddress(ctx context.Context, id uint) (*CustomerAddress, error)
	ListAddresses(ctx context.Context, customerID uint) ([]*CustomerAddress, error)
	UpdateAddress(ctx context.Context, id uint, req *UpdateCustomerAddressRequest) (*CustomerAddress, error)
	DeleteAddress(ctx context.Context, id uint) error
	FindNearby(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*CustomerAddress, error)
}

type service struct {
	repo      Repository
	custCheck CustomerChecker
}

func NewService(repo Repository, custCheck CustomerChecker) Service {
	return &service{repo: repo, custCheck: custCheck}
}

func (s *service) CreateAddress(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddress, error) {
	if req == nil {
		return nil, fmt.Errorf("%w: empty request", ErrInvalidInput)
	}

	if _, err := validation.ValidateStruct(req); err != nil {
		return nil, fmt.Errorf("%w: invalid payload", ErrInvalidInput)
	}

	if s.custCheck != nil {
		ok, err := s.custCheck.Exists(ctx, customerID)
		if err != nil {
			return nil, err
		}
		if !ok {
			return nil, ErrCustomerMissing
		}
	}

	a := &CustomerAddress{
		CustomerID:  customerID,
		ProvinceID:  req.ProvinceID,
		HouseNumber: req.HouseNumber,
		Village:     req.Village,
		Moo:         req.Moo,
		Soi:         req.Soi,
		Road:        req.Road,
		Subdistrict: req.Subdistrict,
		District:    req.District,
		PostalCode:  req.PostalCode,
		Country:     req.Country,
		Latitude:    req.Latitude,
		Longitude:   req.Longitude,
	}

	if err := s.repo.Create(ctx, a); err != nil {
		return nil, fmt.Errorf("failed to create address: %w", err)
	}
	log.Printf("[DEBUG] Created address ID=%d", a.ID)

	if a.ID == 0 {
		return nil, fmt.Errorf("%w: record not created (missing ID, maybe wrong table name)", ErrInvalidInput)
	}

	addr, err := s.repo.GetByID(ctx, a.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to reload created address: %w", err)
	}
	if addr == nil {
		return nil, fmt.Errorf("%w: record missing after create", ErrAddressNotFound)
	}
	return addr, nil
}

func (s *service) GetAddress(ctx context.Context, id uint) (*CustomerAddress, error) {
	a, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if a == nil {
		return nil, ErrAddressNotFound
	}
	return a, nil
}

func (s *service) ListAddresses(ctx context.Context, customerID uint) ([]*CustomerAddress, error) {
	return s.repo.ListByCustomer(ctx, customerID)
}

func (s *service) UpdateAddress(ctx context.Context, id uint, req *UpdateCustomerAddressRequest) (*CustomerAddress, error) {
	a, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if a == nil {
		return nil, ErrAddressNotFound
	}

	if _, err := validation.ValidateStruct(req); err != nil {
		return nil, fmt.Errorf("%w: invalid payload", ErrInvalidInput)
	}

	if req.ProvinceID != nil {
		a.ProvinceID = *req.ProvinceID
	}
	if req.HouseNumber != nil {
		a.HouseNumber = req.HouseNumber
	}
	if req.Village != nil {
		a.Village = req.Village
	}
	if req.Moo != nil {
		a.Moo = req.Moo
	}
	if req.Soi != nil {
		a.Soi = req.Soi
	}
	if req.Road != nil {
		a.Road = req.Road
	}
	if req.Subdistrict != nil {
		a.Subdistrict = req.Subdistrict
	}
	if req.District != nil {
		a.District = req.District
	}
	if req.PostalCode != nil {
		a.PostalCode = req.PostalCode
	}
	if req.Country != nil {
		a.Country = req.Country
	}
	if req.Latitude != nil {
		a.Latitude = req.Latitude
	}
	if req.Longitude != nil {
		a.Longitude = req.Longitude
	}

	if err := s.repo.Update(ctx, a); err != nil {
		return nil, err
	}

	addr, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if addr == nil {
		return nil, ErrAddressNotFound
	}
	return addr, nil
}

func (s *service) DeleteAddress(ctx context.Context, id uint) error {
	a, err := s.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if a == nil {
		return ErrAddressNotFound
	}
	return s.repo.Delete(ctx, id)
}

func (s *service) FindNearby(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*CustomerAddress, error) {
	if radiusKm <= 0 || radiusKm > 100 {
		return nil, fmt.Errorf("%w: radius must be between 0 and 100 km", ErrInvalidInput)
	}
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	return s.repo.SearchNearby(ctx, lat, lon, radiusKm, limit)
}
