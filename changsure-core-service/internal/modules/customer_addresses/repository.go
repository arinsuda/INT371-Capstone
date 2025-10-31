package customeraddresses

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, a *CustomerAddress) error
	GetByID(ctx context.Context, id uint) (*CustomerAddress, error)
	ListByCustomer(ctx context.Context, customerID uint) ([]*CustomerAddress, error)
	Update(ctx context.Context, a *CustomerAddress) error
	Delete(ctx context.Context, id uint) error
	SearchNearby(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*CustomerAddress, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, a *CustomerAddress) error {
	return r.db.WithContext(ctx).Create(a).Error
}

func (r *repository) GetByID(ctx context.Context, id uint) (*CustomerAddress, error) {
	var a CustomerAddress
	err := r.db.WithContext(ctx).
		Preload("Province").
		First(&a, id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

func (r *repository) ListByCustomer(ctx context.Context, customerID uint) ([]*CustomerAddress, error) {
	var list []*CustomerAddress
	err := r.db.WithContext(ctx).
		Where("customer_id = ?", customerID).
		Preload("Province").
		Order("created_at DESC").
		Find(&list).Error
	return list, err
}

func (r *repository) Update(ctx context.Context, a *CustomerAddress) error {
	return r.db.WithContext(ctx).Model(a).Updates(a).Error
}

func (r *repository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&CustomerAddress{}, id).Error
}

func (r *repository) SearchNearby(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*CustomerAddress, error) {
	raw := `
		SELECT * FROM customer_address ca
		WHERE ca.latitude IS NOT NULL AND ca.longitude IS NOT NULL
		  AND ( 6371 * 2 * ASIN(
				SQRT(
					POWER(SIN(RADIANS(ca.latitude  - ?)/2), 2) +
					COS(RADIANS(?)) * COS(RADIANS(ca.latitude)) *
					POWER(SIN(RADIANS(ca.longitude - ?)/2), 2)
				)
			  )) <= ?
		ORDER BY ( 6371 * 2 * ASIN(
				SQRT(
					POWER(SIN(RADIANS(ca.latitude  - ?)/2), 2) +
					COS(RADIANS(?)) * COS(RADIANS(ca.latitude)) *
					POWER(SIN(RADIANS(ca.longitude - ?)/2), 2)
				)
			  ))
		LIMIT ?
	`
	var list []*CustomerAddress
	err := r.db.WithContext(ctx).Raw(raw, lat, lat, lon, radiusKm, lat, lat, lon, limit).Scan(&list).Error
	if err != nil {
		return nil, err
	}

	if len(list) > 0 {
		ids := make([]uint, 0, len(list))
		for _, a := range list { ids = append(ids, a.ID) }
		var full []*CustomerAddress
		if err := r.db.WithContext(ctx).
			Preload("Province").
			Where("id IN ?", ids).
			Find(&full).Error; err == nil {
			return full, nil
		}
	}
	return list, nil
}