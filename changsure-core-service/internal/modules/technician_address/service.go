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
	ErrAddressNotFound = errors.New("address not found")
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

func (s *service) normalizeLocation(
	ctx context.Context,
	provinceID, districtID, subDistrictID *uint,
) (*uint, *uint, *uint, error) {
	return addressshared.NormalizeAndValidateLocation(
		ctx,
		provinceID,
		districtID,
		subDistrictID,
		s.districtRepo,
		s.subDistrictRepo,
	)
}

func shouldBePrimaryOnCreate(existingCount int64, reqPrimary *bool) bool {
	if existingCount == 0 {
		return true
	}
	return reqPrimary != nil && *reqPrimary
}

func (s *service) applyUpdateFields(addr *TechnicianAddress, req *UpdateTechnicianAddressRequest) (locationChanged bool) {
	if req.Label != nil {
		addr.Label = req.Label
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
	if req.Latitude != nil {
		addr.Latitude = req.Latitude
	}
	if req.Longitude != nil {
		addr.Longitude = req.Longitude
	}

	// If client sends is_primary, honor it (business rule),
	// and later enforce uniqueness via SetPrimaryTx in transaction.
	if req.IsPrimary != nil {
		addr.IsPrimary = *req.IsPrimary
	}

	if req.ProvinceID != nil {
		addr.ProvinceID = req.ProvinceID
		locationChanged = true
	}
	if req.DistrictID != nil {
		addr.DistrictID = req.DistrictID
		locationChanged = true
	}
	if req.SubDistrictID != nil {
		addr.SubDistrictID = req.SubDistrictID
		locationChanged = true
	}

	return locationChanged
}

func (s *service) Create(ctx context.Context, techID uint, req *CreateTechnicianAddressRequest) (*TechnicianAddressResponse, error) {
	if err := s.checkOwn(ctx, techID); err != nil {
		return nil, err
	}

	pid, did, sdid, err := s.normalizeLocation(ctx, req.ProvinceID, req.DistrictID, req.SubDistrictID)
	if err != nil {
		return nil, err
	}

	count, err := s.repo.CountByTechnician(ctx, techID)
	if err != nil {
		return nil, err
	}
	primary := shouldBePrimaryOnCreate(count, req.IsPrimary)

	addr := &TechnicianAddress{
		TechnicianID: techID,
		AddressFields: addressshared.AddressFields{
			Label:         req.Label,
			HouseNumber:   req.HouseNumber,
			Village:       req.Village,
			Moo:           req.Moo,
			Soi:           req.Soi,
			Road:          req.Road,
			ProvinceID:    pid,
			DistrictID:    did,
			SubDistrictID: sdid,
			Latitude:      req.Latitude,
			Longitude:     req.Longitude,
			IsPrimary:     primary,
		},
	}

	// Atomic: create + (optional) set primary in one transaction
	if err := s.repo.Transaction(ctx, func(r Repository) error {
		if err := r.Create(ctx, addr); err != nil {
			return err
		}
		if primary {
			return r.SetPrimaryTx(ctx, techID, addr.ID)
		}
		return nil
	}); err != nil {
		return nil, err
	}

	newAddr, _ := s.repo.Get(ctx, addr.ID, techID)
	phone, _ := s.repo.GetTechnicianPhone(ctx, techID)
	resp := ToResponse(newAddr, phone)
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

	locationChanged := s.applyUpdateFields(addr, req)

	if locationChanged {
		pid, did, sdid, err := s.normalizeLocation(ctx, addr.ProvinceID, addr.DistrictID, addr.SubDistrictID)
		if err != nil {
			return nil, err
		}
		addr.ProvinceID = pid
		addr.DistrictID = did
		addr.SubDistrictID = sdid
	}

	// Atomic: update + (optional) set primary uniqueness
	if err := s.repo.Transaction(ctx, func(r Repository) error {
		if err := r.Update(ctx, addr); err != nil {
			return err
		}
		if addr.IsPrimary {
			return r.SetPrimaryTx(ctx, techID, id)
		}
		return nil
	}); err != nil {
		return nil, err
	}

	updatedAddr, _ := s.repo.Get(ctx, id, techID)
	phone, _ := s.repo.GetTechnicianPhone(ctx, techID)
	resp := ToResponse(updatedAddr, phone)
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

	return s.repo.Transaction(ctx, func(r Repository) error {
		if err := r.DeleteTx(ctx, id, techID); err != nil {
			return err
		}

		// If deleting primary, choose a next primary candidate and set it.
		if addr.IsPrimary {
			next, err := r.FindNextPrimaryCandidateTx(ctx, techID, id)
			if err != nil {
				return err
			}
			if next != nil {
				return r.SetPrimaryTx(ctx, techID, next.ID)
			}
		}

		return nil
	})
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

	phone, _ := s.repo.GetTechnicianPhone(ctx, techID)
	resp := ToResponse(addr, phone)
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

	phone, _ := s.repo.GetTechnicianPhone(ctx, techID)
	return ToResponseList(addrs, phone), nil
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

	return s.repo.Transaction(ctx, func(r Repository) error {
		return r.SetPrimaryTx(ctx, techID, id)
	})
}

func (s *service) FindNearby(ctx context.Context, q addressshared.NearbyQuery) ([]addressshared.NearbyTechnicianResult, error) {
	// optional: you could normalize q defaults here, but repo already guards it
	return s.repo.FindNearby(ctx, q)
}

func (s *service) ListPublic(ctx context.Context, techID uint) ([]TechnicianAddressResponse, error) {
	addrs, err := s.repo.ListByTechnician(ctx, techID)
	if err != nil {
		return nil, err
	}

	phone, _ := s.repo.GetTechnicianPhone(ctx, techID)
	return ToResponseList(addrs, phone), nil
}
