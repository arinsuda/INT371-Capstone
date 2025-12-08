package technicianmatching

import (
	"context"

	custaddr "changsure-core-service/internal/modules/customer_address"
	technicians "changsure-core-service/internal/modules/technician"
	techaddr "changsure-core-service/internal/modules/technician_address"
	"gorm.io/gorm"
)

type Repository interface {
	SearchTechnicians(ctx context.Context, q TechnicianSearchQuery) ([]technicians.Technician, error)
	FindByID(ctx context.Context, id uint) (*technicians.Technician, error)

	GetCustomerPrimaryAddress(ctx context.Context, customerID uint) (float64, float64, error)
	GetTechnicianPrimaryAddress(ctx context.Context, techID uint) (float64, float64, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) SearchTechnicians(ctx context.Context, q TechnicianSearchQuery) ([]technicians.Technician, error) {
	tx := r.db.WithContext(ctx).
		Preload("Services", "is_active = TRUE").
		Preload("Services.Service").
		Preload("Badges.Badge").
		Preload("ServiceAreas.Province")

	// Filter by service
	if q.ServiceID != nil {
		tx = tx.Joins(`
			JOIN technician_services ts 
			ON ts.technician_id = technicians.id
			AND ts.service_id = ?
			AND ts.is_active = TRUE
		`, *q.ServiceID)
	}

	// Filter by province (service area)
	if q.ProvinceID != nil {
		tx = tx.Joins(`
			JOIN technician_service_areas tsa 
			ON tsa.technician_id = technicians.id
			AND tsa.province_id = ?
			AND tsa.is_active = TRUE
		`, *q.ProvinceID)
	}

	// JOIN technician primary address
	tx = tx.Joins(`
		LEFT JOIN technician_addresses ta
		ON ta.technician_id = technicians.id
		AND ta.is_primary = TRUE
	`)

	var list []technicians.Technician
	err := tx.Group("technicians.id").Find(&list).Error
	return list, err
}

func (r *repository) FindByID(ctx context.Context, id uint) (*technicians.Technician, error) {
	var t technicians.Technician

	err := r.db.WithContext(ctx).
		Preload("Services.Service").
		Preload("ServiceAreas.Province").
		Preload("Badges.Badge").
		Preload("Addresses", "is_primary = TRUE").
		First(&t, id).Error

	if err != nil {
		return nil, err
	}

	return &t, nil
}

func (r *repository) GetTechnicianPrimaryAddress(ctx context.Context, techID uint) (float64, float64, error) {
	var addr techaddr.TechnicianAddress

	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND is_primary = TRUE", techID).
		First(&addr).Error

	if err != nil {
		return 0, 0, err
	}

	return *addr.Latitude, *addr.Longitude, nil
}

func (r *repository) GetCustomerPrimaryAddress(ctx context.Context, customerID uint) (float64, float64, error) {
	var addr custaddr.CustomerAddress

	err := r.db.WithContext(ctx).
		Where("customer_id = ? AND is_primary = TRUE", customerID).
		First(&addr).Error

	if err != nil {
		return 0, 0, err
	}

	return *addr.Latitude, *addr.Longitude, nil
}
