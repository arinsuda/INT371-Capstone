package technicianaddress

import (
	"context"
	"errors"

	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/pkg/security"
	"changsure-core-service/pkg/utils"
)

var (
	ErrAddressNotFound     = errors.New("address not found")
	ErrCannotDeletePrimary = errors.New("cannot delete primary address")
)

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

func (s *service) checkOwn(ctx context.Context, techID uint) error {
	requesterID := utils.GetUserIDFromContext(ctx)
	return security.CheckOwner(techID, requesterID)
}

func (s *service) Create(ctx context.Context, techID uint, req *CreateTechnicianAddressRequest) (*TechnicianAddress, error) {

	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}

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

	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}

	addr, err := s.repo.Get(ctx, id, techID)
	if err != nil {
		return nil, ErrAddressNotFound
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
		_ = s.repo.ClearPrimary(ctx, techID)
	}
	addr.IsPrimary = req.IsPrimary

	if err := s.repo.Update(ctx, addr); err != nil {
		return nil, err
	}

	return addr, nil
}

func (s *service) Delete(ctx context.Context, id uint, techID uint) error {

	if err := s.checkOwn(ctx, techID); err != nil {
		return err
	}

	addr, err := s.repo.Get(ctx, id, techID)
	if err != nil {
		return ErrAddressNotFound
	}

	if addr.IsPrimary {
		return ErrCannotDeletePrimary
	}

	return s.repo.Delete(ctx, id, techID)
}

func (s *service) Get(ctx context.Context, id uint, techID uint) (*TechnicianAddress, error) {

	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}

	return s.repo.Get(ctx, id, techID)
}

func (s *service) List(ctx context.Context, techID uint) ([]*TechnicianAddress, error) {

	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}

	return s.repo.ListByTechnician(ctx, techID)
}

func (s *service) SetPrimary(ctx context.Context, id uint, techID uint) error {

	if err := s.checkOwn(ctx, techID); err != nil {
		return err
	}

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
