package technicianbadge

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	Create(ctx context.Context, tb *TechnicianBadge) error
	FindByTechnician(ctx context.Context, techID uint) ([]TechnicianBadge, error)
	DeleteByTechAndBadge(ctx context.Context, techID, badgeID uint) error
	PreloadBadge(ctx context.Context, tb *TechnicianBadge) error

	CheckBadgeExists(ctx context.Context, techID, badgeID uint) (bool, error)
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(ctx context.Context, tb *TechnicianBadge) error {
	return r.db.WithContext(ctx).Create(tb).Error
}

func (r *repository) FindByTechnician(ctx context.Context, techID uint) ([]TechnicianBadge, error) {
	var items []TechnicianBadge
	err := r.db.WithContext(ctx).
		Where("technician_id = ?", techID).
		Preload("Badge").
		Find(&items).Error
	return items, err
}

func (r *repository) DeleteByTechAndBadge(ctx context.Context, techID, badgeID uint) error {
	return r.db.WithContext(ctx).
		Where("technician_id = ? AND badge_id = ?", techID, badgeID).
		Delete(&TechnicianBadge{}).Error
}

func (r *repository) PreloadBadge(ctx context.Context, tb *TechnicianBadge) error {
	return r.db.WithContext(ctx).
		Preload("Badge").
		First(tb, tb.ID).Error
}

func (r *repository) CheckBadgeExists(ctx context.Context, techID, badgeID uint) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&TechnicianBadge{}).
		Where("technician_id = ? AND badge_id = ?", techID, badgeID).
		Count(&count).Error
	return count > 0, err
}
