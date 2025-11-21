package technician_services

import "context"

type Service interface {
	SetPricing(ctx context.Context, req TechnicianPricingReq) (uint, error)
	SearchTechnicians(ctx context.Context, q SearchTechniciansQuery) ([]interface{}, int64, error)
}

type service struct{ repo Repository }

func NewService(r Repository) Service { return &service{repo: r} }

func (s *service) SetPricing(ctx context.Context, req TechnicianPricingReq) (uint, error) {
	p := &TechnicianService{
		TechnicianID: req.TechnicianID,
		ServiceID:    req.ServiceID,
		PricingType:  req.PricingType,
		PriceFixed:   req.PriceFixed,
		PriceMin:     req.PriceMin,
		PriceMax:     req.PriceMax,
	}
	if req.IsActive != nil {
		p.IsActive = *req.IsActive
	}

	if err := s.repo.Upsert(p); err != nil {
		return 0, err
	}
	return p.ID, nil
}

func (s *service) SearchTechnicians(ctx context.Context, q SearchTechniciansQuery) ([]interface{}, int64, error) {
	items, total, err := s.repo.Search(q)
	if err != nil {
		return nil, 0, err
	}
	results := make([]interface{}, len(items))
	for i, t := range items {
		results[i] = t
	}
	return results, total, nil
}
