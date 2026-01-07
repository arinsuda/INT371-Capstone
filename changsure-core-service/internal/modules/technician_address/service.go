package technicianaddress

import (
	"context"
	"errors"

	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/internal/modules/district"
	subdistrict "changsure-core-service/internal/modules/sub_district"
	"changsure-core-service/pkg/security"
	"changsure-core-service/pkg/utils"
)

var (
	ErrAddressNotFound     = errors.New("address not found")
	ErrCannotDeletePrimary = errors.New("cannot delete primary address")
)

type Service interface {
	Create(ctx context.Context, techID uint, req *CreateTechnicianAddressRequest) (*TechnicianAddressResponse, error)
	Update(ctx context.Context, id uint, techID uint, req *UpdateTechnicianAddressRequest) (*TechnicianAddressResponse, error)
	Delete(ctx context.Context, id uint, techID uint) error
	Get(ctx context.Context, id uint, techID uint) (*TechnicianAddressResponse, error)
	List(ctx context.Context, techID uint) ([]TechnicianAddressResponse, error)
	SetPrimary(ctx context.Context, id uint, techID uint) error

	FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error)

	ListPublic(ctx context.Context, techID uint) ([]TechnicianAddressResponse, error)
}

type service struct {
	repo            Repository
	districtRepo    district.Repository
	subDistrictRepo subdistrict.Repository
}

func NewService(
	repo Repository,
	districtRepo district.Repository,
	subDistrictRepo subdistrict.Repository,
) Service {
	return &service{
		repo:            repo,
		districtRepo:    districtRepo,
		subDistrictRepo: subDistrictRepo,
	}
}

func (s *service) checkOwn(ctx context.Context, techID uint) error {
	requesterID := utils.GetUserIDFromContext(ctx)
	return security.CheckOwner(techID, requesterID)
}

func (s *service) Create(ctx context.Context, techID uint, req *CreateTechnicianAddressRequest) (*TechnicianAddressResponse, error) {
	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}

	pid, did, sdid, err := addressshared.NormalizeAndValidateLocation(
		ctx,
		req.ProvinceID,
		req.DistrictID,
		req.SubDistrictID,
		s.districtRepo,
		s.subDistrictRepo,
	)
	if err != nil {
		return nil, err
	}

	isPrimary := false
	existing, _ := s.repo.ListByTechnician(ctx, techID)
	if len(existing) == 0 {
		isPrimary = true
	} else if req.IsPrimary != nil && *req.IsPrimary {

		if err := s.repo.ClearPrimary(ctx, techID); err != nil {
			return nil, err
		}
		isPrimary = true
	}

	addr := &TechnicianAddress{
		TechnicianID: techID,
		AddressFields: addressshared.AddressFields{
			HouseNumber:   req.HouseNumber,
			Village:       req.Village,
			Moo:           req.Moo,
			Soi:           req.Soi,
			Road:          req.Road,
			SubDistrictID: sdid,
			DistrictID:    did,
			ProvinceID:    pid,
			Latitude:      req.Latitude,
			Longitude:     req.Longitude,
			IsPrimary:     isPrimary,
		},
	}

	if err := s.repo.Create(ctx, addr); err != nil {
		return nil, err
	}

	newAddr, _ := s.repo.Get(ctx, addr.ID, techID)
	resp := ToResponse(newAddr)
	return &resp, nil
}

func (s *service) Update(ctx context.Context, id uint, techID uint, req *UpdateTechnicianAddressRequest) (*TechnicianAddressResponse, error) {
	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}

	addr, err := s.repo.Get(ctx, id, techID)
	if err != nil {
		return nil, err
	}
	if addr == nil {
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

	effectiveProvinceID := addr.ProvinceID
	effectiveDistrictID := addr.DistrictID
	effectiveSubDistrictID := addr.SubDistrictID

	locationChanged := false
	if req.ProvinceID != nil {
		effectiveProvinceID = req.ProvinceID
		locationChanged = true
	}
	if req.DistrictID != nil {
		effectiveDistrictID = req.DistrictID
		locationChanged = true
	}
	if req.SubDistrictID != nil {
		effectiveSubDistrictID = req.SubDistrictID
		locationChanged = true
	}

	if locationChanged {
		pid, did, sdid, err := addressshared.NormalizeAndValidateLocation(
			ctx,
			effectiveProvinceID,
			effectiveDistrictID,
			effectiveSubDistrictID,
			s.districtRepo,
			s.subDistrictRepo,
		)
		if err != nil {
			return nil, err
		}
		addr.ProvinceID = pid
		addr.DistrictID = did
		addr.SubDistrictID = sdid
	}

	if req.Latitude != nil {
		addr.Latitude = req.Latitude
	}
	if req.Longitude != nil {
		addr.Longitude = req.Longitude
	}

	if req.IsPrimary != nil && *req.IsPrimary {
		if !addr.IsPrimary {
			_ = s.repo.ClearPrimary(ctx, techID)
			addr.IsPrimary = true
		}
	}

	if err := s.repo.Update(ctx, addr); err != nil {
		return nil, err
	}

	updatedAddr, _ := s.repo.Get(ctx, id, techID)
	resp := ToResponse(updatedAddr)
	return &resp, nil
}

func (s *service) Delete(ctx context.Context, id uint, techID uint) error {
	if err := s.checkOwn(ctx, techID); err != nil {
		return err
	}
	addr, err := s.repo.Get(ctx, id, techID)
	if err != nil {
		return err
	}
	if addr == nil {
		return ErrAddressNotFound
	}
	if addr.IsPrimary {
		return ErrCannotDeletePrimary
	}
	return s.repo.Delete(ctx, id, techID)
}

func (s *service) Get(ctx context.Context, id uint, techID uint) (*TechnicianAddressResponse, error) {
	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}
	addr, err := s.repo.Get(ctx, id, techID)
	if err != nil {
		return nil, err
	}
	if addr == nil {
		return nil, ErrAddressNotFound
	}
	resp := ToResponse(addr)
	return &resp, nil
}

func (s *service) List(ctx context.Context, techID uint) ([]TechnicianAddressResponse, error) {
	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}
	addrs, err := s.repo.ListByTechnician(ctx, techID)
	if err != nil {
		return nil, err
	}
	return ToResponseList(addrs), nil
}

func (s *service) SetPrimary(ctx context.Context, id uint, techID uint) error {
	if err := s.checkOwn(ctx, techID); err != nil {
		return err
	}
	addr, err := s.repo.Get(ctx, id, techID)
	if err != nil {
		return err
	}
	if addr == nil {
		return ErrAddressNotFound
	}
	if err := s.repo.ClearPrimary(ctx, techID); err != nil {
		return err
	}
	addr.IsPrimary = true
	return s.repo.Update(ctx, addr)
}

func (s *service) FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error) {
	return s.repo.FindNearby(ctx, q)
}

func (s *service) ListPublic(ctx context.Context, techID uint) ([]TechnicianAddressResponse, error) {
	addrs, err := s.repo.ListByTechnician(ctx, techID)
	if err != nil {
		return nil, err
	}
	return ToResponseList(addrs), nil
}
