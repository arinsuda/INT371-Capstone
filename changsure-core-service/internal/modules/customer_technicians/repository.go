package customer_technicians

import (
	"context"

	technicians "changsure-core-service/internal/modules/technicians"
	"gorm.io/gorm"
)

type Repository interface {
	List(ctx context.Context, q TechnicianListQuery) ([]technicians.Technician, error)
	GetByID(ctx context.Context, id uint) (*technicians.Technician, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) List(ctx context.Context, q TechnicianListQuery) ([]technicians.Technician, error) {
	tx := r.db.WithContext(ctx).
		Preload("Services", "is_active = ?", true).
		Preload("Services.Service").
		Preload("ServiceAreas").
		Preload("ServiceAreas.Province").
		Preload("Badges").
		Preload("Badges.Badge")

	if q.ServiceID != nil {
		tx = tx.Joins(`
            JOIN technician_services ts 
                ON ts.technician_id = technicians.id 
                AND ts.service_id = ?
                AND ts.is_active = true
        `, *q.ServiceID)
	}

	if q.ProvinceID != nil {
		tx = tx.Joins(`
            JOIN technician_service_areas tsa
                ON tsa.technician_id = technicians.id
                AND tsa.province_id = ?
                AND tsa.is_active = true
        `, *q.ProvinceID)
	}

	var list []technicians.Technician
	err := tx.Find(&list).Error
	return list, err
}

func (r *repository) GetByID(ctx context.Context, id uint) (*technicians.Technician, error) {
	var t technicians.Technician
	err := r.db.WithContext(ctx).
		Preload("Services").
		Preload("Services.Service").
		Preload("ServiceAreas").
		Preload("ServiceAreas.Province").
		Preload("Badges").
		Preload("Badges.Badge").
		First(&t, id).Error

	if err != nil {
		return nil, err
	}
	return &t, nil
}
