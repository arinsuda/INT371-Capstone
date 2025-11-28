package technician_addresses

import "context"

type Service interface {
	AddAddress(ctx context.Context, techID uint, in CreateTechAddressReq) (uint, error)
	UpdateAddress(ctx context.Context, id uint, in UpdateTechAddressReq) error
	DeleteAddress(ctx context.Context, id uint) error
	ListAddresses(ctx context.Context, techID uint) ([]TechnicianAddress, error)
	FindNearby(ctx context.Context, q NearQuery) ([]TechnicianAddress, error)
}

type service struct{ repo Repository }

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) AddAddress(ctx context.Context, techID uint, in CreateTechAddressReq) (uint, error) {
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

	if err := s.repo.Create(ctx, m); err != nil {
		return 0, err
	}

	return m.ID, nil
}

func (s *service) UpdateAddress(ctx context.Context, id uint, in UpdateTechAddressReq) error {
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

	if len(fields) == 0 {
		return nil
	}

	return s.repo.Update(ctx, id, fields)
}

func (s *service) DeleteAddress(ctx context.Context, id uint) error {
	return s.repo.Delete(ctx, id)
}

func (s *service) ListAddresses(ctx context.Context, techID uint) ([]TechnicianAddress, error) {
	return s.repo.ListByTechnician(ctx, techID)
}

func (s *service) FindNearby(ctx context.Context, q NearQuery) ([]TechnicianAddress, error) {
	return s.repo.FindNearby(ctx, q)
}
