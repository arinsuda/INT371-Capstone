package timeslot

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	FindAll(ctx context.Context) ([]TimeSlot, error)
	FindActive(ctx context.Context) ([]TimeSlot, error)
	FindByID(ctx context.Context, id uint) (*TimeSlot, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindAll(ctx context.Context) ([]TimeSlot, error) {
	var slots []TimeSlot
	err := r.db.WithContext(ctx).
		Order("start_time ASC").
		Find(&slots).Error
	return slots, err
}

func (r *repository) FindActive(ctx context.Context) ([]TimeSlot, error) {
	var slots []TimeSlot
	err := r.db.WithContext(ctx).
		Where("is_active = ?", true).
		Order("start_time ASC").
		Find(&slots).Error
	return slots, err
}

func (r *repository) FindByID(ctx context.Context, id uint) (*TimeSlot, error) {
	var slot TimeSlot
	err := r.db.WithContext(ctx).First(&slot, id).Error
	if err != nil {
		return nil, err
	}
	return &slot, nil
}
