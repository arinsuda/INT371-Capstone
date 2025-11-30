package customer_addresses

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, addr *CustomerAddress) error
	Update(ctx context.Context, addr *CustomerAddress) error
	Delete(ctx context.Context, id uint, customerID uint) error
	Get(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error)
	ListByCustomer(ctx context.Context, customerID uint) ([]*CustomerAddress, error)
	ClearPrimary(ctx context.Context, customerID uint) error
}

type repo struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repo{db: db}
}

func (r *repo) Create(ctx context.Context, addr *CustomerAddress) error {
	return r.db.WithContext(ctx).
		Create(addr).Error
}

func (r *repo) Update(ctx context.Context, addr *CustomerAddress) error {
	return r.db.WithContext(ctx).
		Model(&CustomerAddress{}).
		Where("id = ? AND customer_id = ?", addr.ID, addr.CustomerID).
		Updates(addr).Error
}

func (r *repo) Delete(ctx context.Context, id uint, customerID uint) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND customer_id = ?", id, customerID).
		Delete(&CustomerAddress{}).Error
}

func (r *repo) Get(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error) {
	var addr CustomerAddress
	err := r.db.WithContext(ctx).
		Where("id = ? AND customer_id = ?", id, customerID).
		First(&addr).Error

	if err != nil {
		return nil, err
	}
	return &addr, nil
}

func (r *repo) ListByCustomer(ctx context.Context, customerID uint) ([]*CustomerAddress, error) {
	var out []*CustomerAddress
	err := r.db.WithContext(ctx).
		Where("customer_id = ?", customerID).
		Order("is_primary DESC").
		Find(&out).Error

	return out, err
}

func (r *repo) ClearPrimary(ctx context.Context, customerID uint) error {
	return r.db.WithContext(ctx).
		Model(&CustomerAddress{}).
		Where("customer_id = ?", customerID).
		Update("is_primary", false).Error
}
