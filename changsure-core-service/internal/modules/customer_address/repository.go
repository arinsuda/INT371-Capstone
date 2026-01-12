package customeraddress

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, addr *CustomerAddress) error
	Update(ctx context.Context, addr *CustomerAddress) error
	Delete(ctx context.Context, id uint, customerID uint) error

	FindByID(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error)
	FindAllByCustomerID(ctx context.Context, customerID uint) ([]*CustomerAddress, error)

	SetPrimary(ctx context.Context, customerID uint, addressID uint) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, addr *CustomerAddress) error {
	return r.db.WithContext(ctx).Create(addr).Error
}

func (r *repository) Update(ctx context.Context, addr *CustomerAddress) error {
	return r.db.WithContext(ctx).Model(addr).Updates(addr).Error
}

func (r *repository) Delete(ctx context.Context, id uint, customerID uint) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND customer_id = ?", id, customerID).
		Delete(&CustomerAddress{}).Error
}

func (r *repository) FindByID(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error) {
	var addr CustomerAddress
	err := r.db.WithContext(ctx).
		Preload("SubDistrict").
		Preload("District").
		Preload("Province").
		Where("id = ? AND customer_id = ?", id, customerID).
		First(&addr).Error

	if err != nil {
		return nil, err
	}
	return &addr, nil
}

func (r *repository) FindAllByCustomerID(ctx context.Context, customerID uint) ([]*CustomerAddress, error) {
	var addrs []*CustomerAddress
	err := r.db.WithContext(ctx).
		Preload("SubDistrict").
		Preload("District").
		Preload("Province").
		Where("customer_id = ?", customerID).
		Order("is_primary DESC, created_at DESC").
		Find(&addrs).Error

	return addrs, err
}

func (r *repository) SetPrimary(ctx context.Context, customerID uint, addressID uint) error {
	return r.db.Transaction(func(tx *gorm.DB) error {

		if err := tx.Model(&CustomerAddress{}).
			Where("customer_id = ?", customerID).
			Update("is_primary", false).Error; err != nil {
			return err
		}

		if err := tx.Model(&CustomerAddress{}).
			Where("id = ? AND customer_id = ?", addressID, customerID).
			Update("is_primary", true).Error; err != nil {
			return err
		}
		return nil
	})
}
