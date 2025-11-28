package technician_addresses

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, m *TechnicianAddress) error
	Update(ctx context.Context, id uint, fields map[string]any) error
	Delete(ctx context.Context, id uint) error
	Get(ctx context.Context, id uint) (*TechnicianAddress, error)
	ListByTechnician(ctx context.Context, technicianID uint) ([]TechnicianAddress, error)
	FindNearby(ctx context.Context, q NearQuery) ([]TechnicianAddress, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, m *TechnicianAddress) error {
	return r.db.WithContext(ctx).Create(m).Error
}

func (r *repository) Update(ctx context.Context, id uint, fields map[string]any) error {
	return r.db.WithContext(ctx).Model(&TechnicianAddress{}).Where("id = ?", id).Updates(fields).Error
}

func (r *repository) Delete(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&TechnicianAddress{}, id).Error
}

func (r *repository) Get(ctx context.Context, id uint) (*TechnicianAddress, error) {
	var m TechnicianAddress
	if err := r.db.WithContext(ctx).First(&m, id).Error; err != nil {
		return nil, err
	}
	return &m, nil
}

func (r *repository) ListByTechnician(ctx context.Context, technicianID uint) ([]TechnicianAddress, error) {
	var items []TechnicianAddress
	if err := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID).
		Order("is_primary DESC").
		Find(&items).
		Error; err != nil {
		return nil, err
	}
	return items, nil
}

func (r *repository) FindNearby(ctx context.Context, q NearQuery) ([]TechnicianAddress, error) {
	var items []TechnicianAddress

	query := `
		(6371 * acos(
			cos(radians(?)) * cos(radians(latitude)) *
			cos(radians(longitude) - radians(?)) +
			sin(radians(?)) * sin(radians(latitude))
		)) <= ?
	`

	if err := r.db.WithContext(ctx).
		Where(query, q.Lat, q.Lng, q.Lat, q.KM).
		Find(&items).Error; err != nil {
		return nil, err
	}

	return items, nil
}
