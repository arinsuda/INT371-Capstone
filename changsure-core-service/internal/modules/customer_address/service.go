package customeraddress

import (
	"context"
	"errors"

	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/internal/modules/district"
	subdistrict "changsure-core-service/internal/modules/sub_district"
	"changsure-core-service/pkg/utils"
)

var (
	ErrNotFound     = errors.New("address not found")
	ErrUnauthorized = errors.New("unauthorized")
)

type Service interface {
	Create(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddressResponse, error)
	Update(ctx context.Context, id uint, customerID uint, req *UpdateCustomerAddressRequest) (*CustomerAddressResponse, error)
	Delete(ctx context.Context, id uint, customerID uint) error
	Get(ctx context.Context, id uint, customerID uint) (*CustomerAddressResponse, error)
	List(ctx context.Context, customerID uint) ([]CustomerAddressResponse, error)
	SetPrimary(ctx context.Context, id uint, customerID uint) error
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

func (s *service) checkOwner(ctx context.Context, customerID uint) error {
	userID := utils.GetUserIDFromContext(ctx)
	if userID == 0 || userID != customerID {
		return ErrUnauthorized
	}
	return nil
}

func shouldBePrimaryOnCreate(existingCount int, reqPrimary *bool) bool {
	if existingCount == 0 {
		return true
	}
	return reqPrimary != nil && *reqPrimary
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

func (s *service) applyUpdateFields(addr *CustomerAddress, req *UpdateCustomerAddressRequest) (locationChanged bool) {
	if req.Label != nil {
		addr.Label = req.Label
	}

	if req.PhoneNumber != nil {
		addr.PhoneNumber = req.PhoneNumber
	}

	if req.AddressLine != nil {
		addr.AddressLine = req.AddressLine
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

func (s *service) Create(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddressResponse, error) {
	if err := s.checkOwner(ctx, customerID); err != nil {
		return nil, err
	}

	pid, did, sdid, err := s.normalizeLocation(ctx, req.ProvinceID, req.DistrictID, req.SubDistrictID)
	if err != nil {
		return nil, err
	}

	existing, err := s.repo.FindAllByCustomerID(ctx, customerID)
	if err != nil {
		return nil, err
	}

	primary := shouldBePrimaryOnCreate(len(existing), req.IsPrimary)

	addr := &CustomerAddress{
		CustomerID: customerID,
		AddressFields: addressshared.AddressFields{
			Label:         req.Label,
			PhoneNumber:   req.PhoneNumber,
			HouseNumber:   req.HouseNumber,
			AddressLine:   req.AddressLine,
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

	addressshared.NormalizeAddressFields(&addr.AddressFields)
	addressshared.ParseAddressLineToStructured(&addr.AddressFields)
	if err := addressshared.ValidateAddressFields(&addr.AddressFields); err != nil {
		return nil, err
	}

	if err := s.repo.Transaction(ctx, func(r Repository) error {
		if err := r.Create(ctx, addr); err != nil {
			return err
		}
		if primary {
			return r.SetPrimaryTx(ctx, customerID, addr.ID)
		}
		return nil
	}); err != nil {
		return nil, err
	}

	newAddr, err := s.repo.FindByID(ctx, addr.ID, customerID)
	if err != nil {
		return nil, err
	}

	defaultPhone, err := s.repo.GetCustomerPhone(ctx, customerID)
	if err != nil {
		return nil, err
	}

	resp := ToResponse(newAddr, defaultPhone)
	return &resp, nil
}

func (s *service) Update(ctx context.Context, id uint, customerID uint, req *UpdateCustomerAddressRequest) (*CustomerAddressResponse, error) {
	if err := s.checkOwner(ctx, customerID); err != nil {
		return nil, err
	}

	addr, err := s.repo.FindByID(ctx, id, customerID)
	if err != nil {
		return nil, err
	}
	if addr == nil {
		return nil, ErrNotFound
	}

	locationChanged := s.applyUpdateFields(addr, req)

	if req.AddressLine != nil {
		addr.AddressLine = req.AddressLine

		if req.HouseNumber == nil {
			addr.HouseNumber = nil
		}
		if req.Moo == nil {
			addr.Moo = nil
		}
		if req.Soi == nil {
			addr.Soi = nil
		}
		if req.Road == nil {
			addr.Road = nil
		}
		if req.Village == nil {
			addr.Village = nil
		}
	}

	addressshared.NormalizeAddressFields(&addr.AddressFields)
	addressshared.ParseAddressLineToStructured(&addr.AddressFields)

	if err := addressshared.ValidateAddressFields(&addr.AddressFields); err != nil {
		return nil, err
	}

	if locationChanged {
		pid, did, sdid, err := s.normalizeLocation(ctx, addr.ProvinceID, addr.DistrictID, addr.SubDistrictID)
		if err != nil {
			return nil, err
		}
		addr.ProvinceID = pid
		addr.DistrictID = did
		addr.SubDistrictID = sdid
	}

	if err := s.repo.Transaction(ctx, func(r Repository) error {
		if err := r.Update(ctx, addr); err != nil {
			return err
		}
		if addr.IsPrimary {
			return r.SetPrimaryTx(ctx, customerID, id)
		}
		return nil
	}); err != nil {
		return nil, err
	}

	updatedAddr, _ := s.repo.FindByID(ctx, id, customerID)
	defaultPhone, err := s.repo.GetCustomerPhone(ctx, customerID)
	if err != nil {
		return nil, err
	}
	resp := ToResponse(updatedAddr, defaultPhone)
	return &resp, nil
}

func (s *service) Delete(ctx context.Context, id uint, customerID uint) error {
	if err := s.checkOwner(ctx, customerID); err != nil {
		return err
	}

	addr, err := s.repo.FindByID(ctx, id, customerID)
	if err != nil {
		return err
	}
	if addr == nil {
		return ErrNotFound
	}

	return s.repo.Transaction(ctx, func(r Repository) error {
		if err := r.DeleteTx(ctx, id, customerID); err != nil {
			return err
		}

		if addr.IsPrimary {
			next, err := r.FindNextPrimaryCandidateTx(ctx, customerID, id)
			if err != nil {
				return err
			}
			if next != nil {
				return r.SetPrimaryTx(ctx, customerID, next.ID)
			}
		}

		return nil
	})
}

func (s *service) Get(ctx context.Context, id uint, customerID uint) (*CustomerAddressResponse, error) {
	if err := s.checkOwner(ctx, customerID); err != nil {
		return nil, err
	}

	addr, err := s.repo.FindByID(ctx, id, customerID)
	if err != nil {
		return nil, err
	}
	if addr == nil {
		return nil, ErrNotFound
	}

	defaultPhone, err := s.repo.GetCustomerPhone(ctx, customerID)
	if err != nil {
		return nil, err
	}
	resp := ToResponse(addr, defaultPhone)
	return &resp, nil
}

func (s *service) List(ctx context.Context, customerID uint) ([]CustomerAddressResponse, error) {
	if err := s.checkOwner(ctx, customerID); err != nil {
		return nil, err
	}

	addrs, err := s.repo.FindAllByCustomerID(ctx, customerID)
	if err != nil {
		return nil, err
	}

	defaultPhone, err := s.repo.GetCustomerPhone(ctx, customerID)
	if err != nil {
		return nil, err
	}
	return ToResponseList(addrs, defaultPhone), nil
}

func (s *service) SetPrimary(ctx context.Context, id uint, customerID uint) error {
	if err := s.checkOwner(ctx, customerID); err != nil {
		return err
	}

	addr, err := s.repo.FindByID(ctx, id, customerID)
	if err != nil {
		return err
	}
	if addr == nil {
		return ErrNotFound
	}

	return s.repo.SetPrimary(ctx, customerID, id)
}
