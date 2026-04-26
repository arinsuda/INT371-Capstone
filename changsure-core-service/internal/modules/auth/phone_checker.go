package auth

import (
	"context"
	"fmt"

	"changsure-core-service/internal/modules/customer"
	"changsure-core-service/internal/modules/technician"
)

type PhoneChecker interface {
	IsTaken(ctx context.Context, phone string, excludeRole string, excludeID uint) (bool, error)
}

type phoneChecker struct {
	customerRepo customer.Repository
	techRepo     technician.Repository
}

func NewPhoneChecker(
	customerRepo customer.Repository,
	techRepo technician.Repository,
) PhoneChecker {
	return &phoneChecker{
		customerRepo: customerRepo,
		techRepo:     techRepo,
	}
}

func (p *phoneChecker) IsTaken(ctx context.Context, phone string, excludeRole string, excludeID uint) (bool, error) {

	if excludeRole != RoleCustomer {
		c, err := p.customerRepo.FindByPhone(ctx, phone)
		if err != nil {
			return false, fmt.Errorf("check customer phone: %w", err)
		}
		if c != nil {
			return true, nil
		}
	} else {
		c, err := p.customerRepo.FindByPhone(ctx, phone)
		if err != nil {
			return false, fmt.Errorf("check customer phone: %w", err)
		}
		if c != nil && c.ID != excludeID {
			return true, nil
		}
	}

	if excludeRole != RoleTechnician {
		t, err := p.techRepo.FindByPhone(ctx, phone)
		if err != nil {
			return false, fmt.Errorf("check technician phone: %w", err)
		}
		if t != nil {
			return true, nil
		}
	} else {
		t, err := p.techRepo.FindByPhone(ctx, phone)
		if err != nil {
			return false, fmt.Errorf("check technician phone: %w", err)
		}
		if t != nil && t.ID != excludeID {
			return true, nil
		}
	}

	return false, nil
}
