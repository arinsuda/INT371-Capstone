package customers

import (
	"context"
	"errors"

	"gorm.io/gorm"
	utils "changsure-core-service/pkg/utils"
)

type Repository interface {
	GetByID(ctx context.Context, id uint) (*Customer, error)
	GetByPhone(ctx context.Context, phone string) (*Customer, error)
	GetByEmail(ctx context.Context, email string) (*Customer, error)

	Create(ctx context.Context, customer *Customer) error
	Update(ctx context.Context, customer *Customer) error
	Delete(ctx context.Context, id uint) error
	GetAll(ctx context.Context, limit, offset int) ([]*Customer, error)

	FindByID(ctx context.Context, id uint) (*Customer, error)
	FindByEmail(ctx context.Context, email string) (*Customer, error)
	ExistsByEmail(ctx context.Context, email string) (bool, error)
	Exists(ctx context.Context, id uint) (bool, error)

	SearchNearbyAddresses(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*Customer, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Exists(ctx context.Context, id uint) (bool, error) {
	var count int64
	if err := r.db.WithContext(ctx).Model(&Customer{}).
		Where("id = ?", id).
		Count(&count).Error; err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *repository) Create(ctx context.Context, customer *Customer) error {
	return r.db.WithContext(ctx).Create(customer).Error
}

func (r *repository) GetByID(ctx context.Context, id uint) (*Customer, error) {
	var customer Customer
	err := r.db.WithContext(ctx).
		Preload("Addresses").
		First(&customer, id).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &customer, nil
}

func (r *repository) GetByPhone(ctx context.Context, phone string) (*Customer, error) {
	var customer Customer
	err := r.db.WithContext(ctx).
		Where("phone = ?", phone).
		Preload("Addresses").
		First(&customer).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &customer, nil
}

func (r *repository) GetByEmail(ctx context.Context, email string) (*Customer, error) {
	var customer Customer
	err := r.db.WithContext(ctx).
		Where("email = ?", email).
		Preload("Addresses").
		First(&customer).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &customer, nil
}

func (r *repository) Update(ctx context.Context, customer *Customer) error {
	return r.db.WithContext(ctx).
		Model(customer).
		Updates(customer).Error
}

func (r *repository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).
		Delete(&Customer{}, id).Error
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
	type idRow struct {
		CustomerID uint `gorm:"column:customer_id"`
	}

	var rows []idRow

	raw := `
		SELECT x.customer_id FROM (
			SELECT
				ca.customer_id AS customer_id,
				( 6371 * 2 * ASIN(
					SQRT(
						POWER(SIN(RADIANS(ca.latitude  - ?)/2), 2) +
						COS(RADIANS(?)) * COS(RADIANS(ca.latitude)) *
						POWER(SIN(RADIANS(ca.longitude - ?)/2), 2)
					)
				)) AS distance_km
			FROM customer_address ca
			WHERE ca.latitude IS NOT NULL AND ca.longitude IS NOT NULL
		) AS x
		WHERE x.distance_km <= ?
		GROUP BY x.customer_id
		ORDER BY MIN(x.distance_km)
		LIMIT ?;
	`

	if err := r.db.WithContext(ctx).Raw(raw, lat, lat, lon, radiusKm, limit).Scan(&rows).Error; err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return []*Customer{}, nil
	}

	ids := make([]uint, 0, len(rows))
	for _, rrow := range rows {
		ids = append(ids, rrow.CustomerID)
	}

	var customers []*Customer

	err := r.db.WithContext(ctx).
		Preload("Addresses").
		Preload("Addresses.Province").
		Where("id IN ?", ids).
		Find(&customers).Error

	return customers, err
}

func (r *repository) FindByID(ctx context.Context, id uint) (*Customer, error) {
	var customer Customer
	err := r.db.WithContext(ctx).
		Where("id = ?", id).
		Preload("Addresses").
		Preload("Addresses.Province").
		First(&customer).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &customer, nil
}

func (r *repository) FindByEmail(ctx context.Context, email string) (*Customer, error) {
	email = utils.NormalizeEmail(email)

	var customer Customer
	err := r.db.WithContext(ctx).
		Where("LOWER(email) = ?", email).
		First(&customer).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &customer, err
}

func (r *repository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	var count int64
	if err := r.db.WithContext(ctx).Model(&Customer{}).
		Where("email = ?", email).
		Count(&count).Error; err != nil {
		return false, err
	}
	return count > 0, nil
}
