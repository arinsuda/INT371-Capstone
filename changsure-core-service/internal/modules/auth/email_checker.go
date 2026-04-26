package auth

import (
	"context"
	"fmt"

	"changsure-core-service/internal/modules/admin"
	"changsure-core-service/internal/modules/customer"
	"changsure-core-service/internal/modules/technician"
)

type EmailChecker interface {
	IsTaken(ctx context.Context, email string, excludeRole string, excludeID uint) (bool, error)
}

type emailChecker struct {
	adminRepo    admin.Repository
	customerRepo customer.Repository
	techRepo     technician.Repository
}

func NewEmailChecker(
	adminRepo admin.Repository,
	customerRepo customer.Repository,
	techRepo technician.Repository,
) EmailChecker {
	return &emailChecker{
		adminRepo:    adminRepo,
		customerRepo: customerRepo,
		techRepo:     techRepo,
	}
}

func (e *emailChecker) IsTaken(ctx context.Context, email string, excludeRole string, excludeID uint) (bool, error) {

	if excludeRole != RoleAdmin {
		a, err := e.adminRepo.FindByEmail(ctx, email)
		if err != nil {
			return false, fmt.Errorf("check admin email: %w", err)
		}
		if a != nil {
			return true, nil
		}
	} else {
		a, err := e.adminRepo.FindByEmail(ctx, email)
		if err != nil {
			return false, fmt.Errorf("check admin email: %w", err)
		}
		if a != nil && a.ID != excludeID {
			return true, nil
		}
	}

	if excludeRole != RoleCustomer {
		c, err := e.customerRepo.FindByEmail(ctx, email)
		if err != nil {
			return false, fmt.Errorf("check customer email: %w", err)
		}
		if c != nil {
			return true, nil
		}
	} else {
		c, err := e.customerRepo.FindByEmail(ctx, email)
		if err != nil {
			return false, fmt.Errorf("check customer email: %w", err)
		}
		if c != nil && c.ID != excludeID {
			return true, nil
		}
	}

	if excludeRole != RoleTechnician {
		t, err := e.techRepo.FindByEmail(ctx, email)
		if err != nil {
			return false, fmt.Errorf("check technician email: %w", err)
		}
		if t != nil {
			return true, nil
		}
	} else {
		t, err := e.techRepo.FindByEmail(ctx, email)
		if err != nil {
			return false, fmt.Errorf("check technician email: %w", err)
		}
		if t != nil && t.ID != excludeID {
			return true, nil
		}
	}

	return false, nil
}
