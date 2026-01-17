package customeraddress

import (
	"context"
	"errors"

	addressshared "changsure-core-service/internal/modules/address_shared"
	"changsure-core-service/internal/modules/district"
	subdistrict "changsure-core-service/internal/modules/sub_district"
	"changsure-core-service/pkg/utils"

	"gorm.io/gorm"
)

var (
	ErrNotFound            = errors.New("address not found")
	ErrCannotDeletePrimary = errors.New("cannot delete primary address")
	ErrUnauthorized        = errors.New("unauthorized")
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

func (s *service) Create(ctx context.Context, customerID uint, req *CreateCustomerAddressRequest) (*CustomerAddressResponse, error) {
	if err := s.checkOwner(ctx, customerID); err != nil {
		return nil, err
	}

	addr := &CustomerAddress{CustomerID: customerID}

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

	addr.Label = req.Label
	addr.HouseNumber = req.HouseNumber
	addr.Village = req.Village
	addr.Moo = req.Moo
	addr.Soi = req.Soi
	addr.Road = req.Road

	addr.SubDistrictID = sdid
	addr.DistrictID = did
	addr.ProvinceID = pid

	addr.Latitude = req.Latitude
	addr.Longitude = req.Longitude

	existing, _ := s.repo.FindAllByCustomerID(ctx, customerID)

	shouldBePrimary := false
	if len(existing) == 0 {
		shouldBePrimary = true
	} else if req.IsPrimary != nil && *req.IsPrimary {
		shouldBePrimary = true
	}

	addr.IsPrimary = shouldBePrimary

	if err := s.repo.Create(ctx, addr); err != nil {
		return nil, err
	}

	if shouldBePrimary {
		if err := s.repo.SetPrimary(ctx, customerID, addr.ID); err != nil {
			return nil, err
		}
	}

	newAddr, _ := s.repo.FindByID(ctx, addr.ID, customerID)
	phone, _ := s.repo.GetCustomerPhone(ctx, customerID)
	resp := ToResponse(newAddr, phone)
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
	// Build effective location pointers from existing + request
	effectiveProvinceID := addr.ProvinceID
	effectiveDistrictID := addr.DistrictID
	effectiveSubDistrictID := addr.SubDistrictID

	if req.ProvinceID != nil {
		effectiveProvinceID = req.ProvinceID
	}
	if req.DistrictID != nil {
		effectiveDistrictID = req.DistrictID
	}
	if req.SubDistrictID != nil {
		effectiveSubDistrictID = req.SubDistrictID
	}

	if req.ProvinceID != nil || req.DistrictID != nil || req.SubDistrictID != nil {
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

	if err := s.repo.Update(ctx, addr); err != nil {
		return nil, err
	}

	if req.IsPrimary != nil && *req.IsPrimary {
		if err := s.repo.SetPrimary(ctx, customerID, id); err != nil {
			return nil, err
		}
	}
	updatedAddr, _ := s.repo.FindByID(ctx, id, customerID)
	phone, _ := s.repo.GetCustomerPhone(ctx, customerID)
	resp := ToResponse(updatedAddr, phone)
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

	return s.repo.(*repository).db.Transaction(func(tx *gorm.DB) error {
		if err := s.repo.DeleteTx(ctx, tx, id, customerID); err != nil {
			return err
		}

		if addr.IsPrimary {
			next, err := s.repo.FindNextPrimaryCandidateTx(ctx, tx, customerID, id)
			if err != nil {
				return err
			}
			if next != nil {
				if err := s.repo.SetPrimaryTx(ctx, tx, customerID, next.ID); err != nil {
					return err
				}
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

	phone, _ := s.repo.GetCustomerPhone(ctx, customerID)
	resp := ToResponse(addr, phone)
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

	phone, _ := s.repo.GetCustomerPhone(ctx, customerID)
	return ToResponseList(addrs, phone), nil
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
