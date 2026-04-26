package registry

import (
	"changsure-core-service/internal/modules/auth"
	"context"
)

type crossCheckerAdapter struct {
	email auth.EmailChecker
	phone auth.PhoneChecker
}

func (a *crossCheckerAdapter) IsEmailTaken(ctx context.Context, email, excludeRole string, excludeID uint) (bool, error) {
	return a.email.IsTaken(ctx, email, excludeRole, excludeID)
}

func (a *crossCheckerAdapter) IsPhoneTaken(ctx context.Context, phone, excludeRole string, excludeID uint) (bool, error) {
	return a.phone.IsTaken(ctx, phone, excludeRole, excludeID)
}
