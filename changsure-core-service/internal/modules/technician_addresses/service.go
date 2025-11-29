package technician_addresses

import (
	"context"
	"errors"
)

type Service interface {
	AddAddress(ctx context.Context, techID uint, in CreateTechAddressReq) (uint, error)
	UpdateAddress(ctx context.Context, id uint, in UpdateTechAddressReq) error
	DeleteAddress(ctx context.Context, id uint) error
	ListAddresses(ctx context.Context, techID uint) ([]TechnicianAddress, error)
	FindNearby(ctx context.Context, q NearQuery) ([]TechnicianAddress, error)
	GetAddress(ctx context.Context, id uint) (*TechnicianAddress, error)
	SetPrimaryAddress(ctx context.Context, techID, addressID uint) error
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

/* --------------------------------------------------- */
/*                     Add Address                     */
/* --------------------------------------------------- */

func (s *service) AddAddress(ctx context.Context, techID uint, in CreateTechAddressReq) (uint, error) {

	// If user wants a new primary → repo clears old primary first
	if in.IsPrimary != nil && *in.IsPrimary {
		if err := s.repo.ClearPrimary(ctx, techID); err != nil {
			return 0, err
		}
	}

	m := &TechnicianAddress{
		TechnicianID: techID,
		AddressLine:  in.AddressLine,
		SubDistrict:  in.SubDistrict,
		District:     in.District,
		Province:     in.Province,
		PostalCode:   in.PostalCode,
		Latitude:     in.Latitude,
		Longitude:    in.Longitude,
		IsPrimary:    false,
	}

	if in.IsPrimary != nil {
		m.IsPrimary = *in.IsPrimary
	}

	// Save via repo
	return s.repo.Create(ctx, m)
}

/* --------------------------------------------------- */
/*                    Update Address                    */
/* --------------------------------------------------- */

func (s *service) UpdateAddress(ctx context.Context, id uint, in UpdateTechAddressReq) error {

	// If making this primary → tell repo to clear others first
	if in.IsPrimary != nil && *in.IsPrimary {
		addr, err := s.repo.Get(ctx, id)
		if err != nil {
			return err
		}
		if err := s.repo.ClearPrimary(ctx, addr.TechnicianID); err != nil {
			return err
		}
	}

	fields := map[string]any{}

	if in.AddressLine != nil {
		fields["address_line"] = *in.AddressLine
	}
	if in.SubDistrict != nil {
		fields["sub_district"] = *in.SubDistrict
	}
	if in.District != nil {
		fields["district"] = *in.District
	}
	if in.Province != nil {
		fields["province"] = *in.Province
	}
	if in.PostalCode != nil {
		fields["postal_code"] = *in.PostalCode
	}
	if in.Latitude != nil {
		fields["latitude"] = *in.Latitude
	}
	if in.Longitude != nil {
		fields["longitude"] = *in.Longitude
	}
	if in.IsPrimary != nil {
		fields["is_primary"] = *in.IsPrimary
	}

	return s.repo.Update(ctx, id, fields)
}

/* --------------------------------------------------- */
/*                     Delete Address                   */
/* --------------------------------------------------- */

func (s *service) DeleteAddress(ctx context.Context, id uint) error {
	return s.repo.Delete(ctx, id)
}

/* --------------------------------------------------- */
/*                     List Addresses                   */
/* --------------------------------------------------- */

func (s *service) ListAddresses(ctx context.Context, techID uint) ([]TechnicianAddress, error) {
	return s.repo.ListByTechnician(ctx, techID)
}

/* --------------------------------------------------- */
/*                     Find Nearby                     */
/* --------------------------------------------------- */

func (s *service) FindNearby(ctx context.Context, q NearQuery) ([]TechnicianAddress, error) {
	return s.repo.FindNearby(ctx, q)
}

/* --------------------------------------------------- */
/*                     Get Address                     */
/* --------------------------------------------------- */

func (s *service) GetAddress(ctx context.Context, id uint) (*TechnicianAddress, error) {
	return s.repo.Get(ctx, id)
}

/* --------------------------------------------------- */
/*                 Set Primary Address                  */
/* --------------------------------------------------- */

func (s *service) SetPrimaryAddress(ctx context.Context, techID, addressID uint) error {

	addr, err := s.repo.Get(ctx, addressID)
	if err != nil {
		return errors.New("address not found")
	}
	if addr.TechnicianID != techID {
		return errors.New("address does not belong to technician")
	}

	// Clear and set new primary via repo
	if err := s.repo.ClearPrimary(ctx, techID); err != nil {
		return err
	}

	return s.repo.Update(ctx, addressID, map[string]any{
		"is_primary": true,
	})
}
