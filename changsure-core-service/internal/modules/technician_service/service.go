package technicianservice

import (
	"context"
	"fmt"
)

type Service interface {
	UpsertPricing(ctx context.Context, techID uint, req UpsertPricingReq) (uint, error)

	SearchTechnicians(ctx context.Context, q SearchTechniciansQuery) (*SearchTechnicianResult, error)

	GetPricing(ctx context.Context, techID, serviceID uint) (*TechnicianService, error)
}

type service struct{ repo Repository }

func NewService(r Repository) Service { return &service{repo: r} }

func (s *service) GetPricing(ctx context.Context, techID, serviceID uint) (*TechnicianService, error) {
	return s.repo.GetPricing(ctx, techID, serviceID)
}

func (s *service) UpsertPricing(ctx context.Context, techID uint, req UpsertPricingReq) (uint, error) {
	if err := validatePricingFields(req); err != nil {
		return 0, err
	}

	p := &TechnicianService{
		TechnicianID: techID,
		ServiceID:    req.ServiceID,
		PricingType:  req.PricingType,
		PriceFixed:   req.PriceFixed,
		PriceMin:     req.PriceMin,
		PriceMax:     req.PriceMax,
		IsActive:     true,
	}
	if req.IsActive != nil {
		p.IsActive = *req.IsActive
	}

	if err := s.repo.Upsert(ctx, p); err != nil {
		return 0, err
	}
	return p.ID, nil
}

func (s *service) SearchTechnicians(ctx context.Context, q SearchTechniciansQuery) (*SearchTechnicianResult, error) {
	q.SetDefaults()

	items, total, err := s.repo.Search(ctx, q)
	if err != nil {
		return nil, err
	}

	return &SearchTechnicianResult{
		Items:    items,
		Total:    total,
		Page:     q.Page,
		PageSize: q.PageSize,
	}, nil
}

func validatePricingFields(req UpsertPricingReq) error {
	switch req.PricingType {
	case "FIXED":
		if req.PriceFixed == nil || *req.PriceFixed <= 0 {
			return fmt.Errorf("price_fixed must be a positive value for FIXED pricing")
		}
	case "RANGE":
		if req.PriceMin == nil || req.PriceMax == nil {
			return fmt.Errorf("price_min and price_max are required for RANGE pricing")
		}
		if *req.PriceMin <= 0 || *req.PriceMax <= 0 {
			return fmt.Errorf("price_min and price_max must be positive values")
		}
		if *req.PriceMin > *req.PriceMax {
			return fmt.Errorf("price_min must not exceed price_max")
		}
	}
	return nil
}
