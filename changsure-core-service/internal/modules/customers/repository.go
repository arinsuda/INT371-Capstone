package customers

import (
	"context"
	"errors"
	"gorm.io/gorm"
)


type Repository interface {
	Create(ctx context.Context, customer *Customer) error
	GetByID(ctx context.Context, id uint) (*Customer, error)
	GetByPhone(ctx context.Context, phone string) (*Customer, error)
	Update(ctx context.Context, customer *Customer) error
	Delete(ctx context.Context, id uint) error
	List(ctx context.Context, limit, offset int) ([]*Customer, error)
	SearchNearby(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*Customer, error)
}


type repository struct {
	db *gorm.DB
}


func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}


func (r *repository) Create(ctx context.Context, customer *Customer) error {
	return r.db.WithContext(ctx).Create(customer).Error
}


func (r *repository) GetByID(ctx context.Context, id uint) (*Customer, error) {
	var customer Customer
	err := r.db.WithContext(ctx).
		Preload("Province").
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
		Preload("Province").
		Where("phone = ?", phone).
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


func (r *repository) List(ctx context.Context, limit, offset int) ([]*Customer, error) {
	var customers []*Customer
	err := r.db.WithContext(ctx).
		Preload("Province").
		Limit(limit).
		Offset(offset).
		Order("created_at DESC").
		Find(&customers).Error
	
	return customers, err
}


func (r *repository) SearchNearby(ctx context.Context, lat, lon, radiusKm float64, limit int) ([]*Customer, error) {
	var customers []*Customer
	
	query := `
		SELECT * FROM customers
		WHERE latitude IS NOT NULL 
		  AND longitude IS NOT NULL
		  AND calculate_distance(?, ?, latitude, longitude) <= ?
		ORDER BY calculate_distance(?, ?, latitude, longitude)
		LIMIT ?
	`
	
	err := r.db.WithContext(ctx).
		Raw(query, lat, lon, radiusKm, lat, lon, limit).
		Scan(&customers).Error
	
	return customers, err
}