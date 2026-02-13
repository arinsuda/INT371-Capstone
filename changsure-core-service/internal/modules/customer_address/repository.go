package customeraddress

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	WithTx(tx *gorm.DB) Repository
	Transaction(ctx context.Context, fn func(r Repository) error) error

	Create(ctx context.Context, addr *CustomerAddress) error
	Update(ctx context.Context, addr *CustomerAddress) error

	FindByID(ctx context.Context, id uint, customerID uint) (*CustomerAddress, error)
	FindAllByCustomerID(ctx context.Context, customerID uint) ([]*CustomerAddress, error)

	DeleteTx(ctx context.Context, id uint, customerID uint) error
	SetPrimaryTx(ctx context.Context, customerID uint, addressID uint) error
	FindNextPrimaryCandidateTx(ctx context.Context, customerID uint, excludeID uint) (*CustomerAddress, error)

	SetPrimary(ctx context.Context, customerID uint, addressID uint) error

	GetCustomerPhone(ctx context.Context, customerID uint) (*string, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) WithTx(tx *gorm.DB) Repository {
	return &repository{db: tx}
}

func (r *repository) Transaction(ctx context.Context, fn func(r Repository) error) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		return fn(r.WithTx(tx))
	})
}

func (r *repository) Create(ctx context.Context, addr *CustomerAddress) error {
	return r.db.WithContext(ctx).Create(addr).Error
}

func (r *repository) Update(ctx context.Context, addr *CustomerAddress) error {
	return r.db.WithContext(ctx).Save(addr).Error
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
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
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

func (r *repository) DeleteTx(ctx context.Context, id uint, customerID uint) error {
	return r.db.WithContext(ctx).
		Where("id = ? AND customer_id = ?", id, customerID).
		Delete(&CustomerAddress{}).Error
}

func (r *repository) SetPrimaryTx(ctx context.Context, customerID uint, addressID uint) error {

	if err := r.db.WithContext(ctx).
		Model(&CustomerAddress{}).
		Where("customer_id = ?", customerID).
		Update("is_primary", false).Error; err != nil {
		return err
	}

	return r.db.WithContext(ctx).
		Model(&CustomerAddress{}).
		Where("id = ? AND customer_id = ?", addressID, customerID).
		Update("is_primary", true).Error
}

func (r *repository) FindNextPrimaryCandidateTx(ctx context.Context, customerID uint, excludeID uint) (*CustomerAddress, error) {
	var next CustomerAddress
	err := r.db.WithContext(ctx).
		Where("customer_id = ? AND id <> ?", customerID, excludeID).
		Order("created_at DESC").
		First(&next).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &next, nil
}

func (r *repository) SetPrimary(ctx context.Context, customerID uint, addressID uint) error {
	return r.Transaction(ctx, func(rr Repository) error {
		return rr.SetPrimaryTx(ctx, customerID, addressID)
	})
}

func (r *repository) GetCustomerPhone(ctx context.Context, customerID uint) (*string, error) {
	var phone *string
	err := r.db.WithContext(ctx).
		Table("customers").
		Select("phone").
		Where("id = ?", customerID).
		Scan(&phone).Error

	return phone, err
}
