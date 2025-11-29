package technician_badges

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, tb *TechnicianBadge) error
	FindByTechnician(ctx context.Context, technicianID uint) ([]TechnicianBadge, error)
	DeleteByID(ctx context.Context, id uint) error
	HardDeleteByID(ctx context.Context, id uint) error
	PreloadBadge(ctx context.Context, tb *TechnicianBadge) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, tb *TechnicianBadge) error {
	return r.db.WithContext(ctx).Create(tb).Error
}

func (r *repository) FindByTechnician(ctx context.Context, technicianID uint) ([]TechnicianBadge, error) {
	var result []TechnicianBadge
	if err := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID).
		Find(&result).Error; err != nil {
		return nil, err
	}
	return result, nil
}

func (r *repository) DeleteByID(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Delete(&TechnicianBadge{}, id).Error
}

func (r *repository) HardDeleteByID(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).Unscoped().Delete(&TechnicianBadge{}, id).Error
}

func (r *repository) PreloadBadge(ctx context.Context, tb *TechnicianBadge) error {
	return r.db.WithContext(ctx).
		Preload("Badge").
		First(tb, tb.ID).Error
}
