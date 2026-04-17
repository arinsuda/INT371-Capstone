package customer

import (
	"context"
	"errors"
	"time"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, customer *Customer) error
	Update(ctx context.Context, customer *Customer) error
	Delete(ctx context.Context, id uint) error
	FindByID(ctx context.Context, id uint) (*Customer, error)
	FindByEmail(ctx context.Context, email string) (*Customer, error)
	FindByPhone(ctx context.Context, phone string) (*Customer, error)
	GetAll(ctx context.Context, limit, offset int) ([]*Customer, error)
	SearchNearbyAddresses(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*Customer, error)
	CountCustomer(ctx context.Context) (int64, error)
	MarkEmailVerified(ctx context.Context, email string) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) CountCustomer(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&Customer{}).
		Where("deleted_at IS NULL").
		Count(&count).Error
	return count, err
}

func (r *repository) Create(ctx context.Context, customer *Customer) error {
	return r.db.WithContext(ctx).Create(customer).Error
}

func (r *repository) Update(ctx context.Context, customer *Customer) error {
	return r.db.WithContext(ctx).
		Model(&Customer{}).
		Where("id = ?", customer.ID).
		Updates(customer).Error
}

func (r *repository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&Customer{}, id).Error
}

func (r *repository) FindByID(ctx context.Context, id uint) (*Customer, error) {
	var customer Customer
	err := r.db.WithContext(ctx).
		Preload("Addresses").
		Preload("Addresses.Province").
		First(&customer, id).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &customer, err
}

func (r *repository) FindByEmail(ctx context.Context, email string) (*Customer, error) {
	var customer Customer
	err := r.db.WithContext(ctx).
		Where("email = ?", email).
		Preload("Addresses").
		First(&customer).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &customer, err
}

func (r *repository) FindByPhone(ctx context.Context, phone string) (*Customer, error) {
	var customer Customer
	err := r.db.WithContext(ctx).
		Where("phone = ?", phone).
		Preload("Addresses").
		First(&customer).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &customer, err
}

func (r *repository) GetAll(ctx context.Context, limit, offset int) ([]*Customer, error) {
	var customers []*Customer
	err := r.db.WithContext(ctx).
		Preload("Addresses").
		Limit(limit).
		Offset(offset).
		Order("created_at DESC").
		Find(&customers).Error
	return customers, err
}

func (r *repository) SearchNearbyAddresses(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*Customer, error) {

	rawSQL := `
		SELECT customer_id FROM customer_addresses
		WHERE latitude IS NOT NULL AND longitude IS NOT NULL
		AND (
			6371 * acos(
				cos(radians(?)) * cos(radians(latitude)) *
				cos(radians(longitude) - radians(?)) +
				sin(radians(?)) * sin(radians(latitude))
			)
		) <= ?
		GROUP BY customer_id
		LIMIT ?
	`

	var ids []uint
	if err := r.db.WithContext(ctx).Raw(rawSQL, lat, lon, lat, radiusKm, limit).Scan(&ids).Error; err != nil {
		return nil, err
	}

	if len(ids) == 0 {
		return []*Customer{}, nil
	}

	var customers []*Customer
	err := r.db.WithContext(ctx).
		Preload("Addresses").
		Preload("Addresses.Province").
		Where("id IN ?", ids).
		Find(&customers).Error

	return customers, err
}

func (r *repository) MarkEmailVerified(ctx context.Context, email string) error {
	now := time.Now()
	return r.db.WithContext(ctx).
		Model(&Customer{}).
		Where("email = ?", email).
		Update("email_verified_at", now).Error
}
