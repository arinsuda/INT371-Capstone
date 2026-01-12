package timeslot

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	FindAll(ctx context.Context) ([]TimeSlot, error)
	FindActive(ctx context.Context) ([]TimeSlot, error)
	FindByID(ctx context.Context, id uint) (*TimeSlot, error)

	GetSlotsForTechnician(ctx context.Context, technicianID uint) ([]TimeSlot, error)

	ReplaceTechnicianSlots(ctx context.Context, technicianID uint, slots []TimeSlot) error
	DeleteTechnicianSlots(ctx context.Context, technicianID uint) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) FindAll(ctx context.Context) ([]TimeSlot, error) {
	var slots []TimeSlot
	err := r.db.WithContext(ctx).Order("start_time ASC").Find(&slots).Error
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

func (r *repository) GetSlotsForTechnician(ctx context.Context, technicianID uint) ([]TimeSlot, error) {
	var slots []TimeSlot
	var count int64

	err := r.db.WithContext(ctx).
		Model(&TimeSlot{}).
		Where("technician_id = ? AND is_active = ?", technicianID, true).
		Count(&count).Error
	if err != nil {
		return nil, err
	}

	if count > 0 {

		err = r.db.WithContext(ctx).
			Where("technician_id = ? AND is_active = ?", technicianID, true).
			Order("start_time ASC").
			Find(&slots).Error
	} else {

		err = r.db.WithContext(ctx).
			Where("technician_id IS NULL AND is_active = ?", true).
			Order("start_time ASC").
			Find(&slots).Error
	}

	return slots, err
}

func (r *repository) ReplaceTechnicianSlots(ctx context.Context, technicianID uint, slots []TimeSlot) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		if err := tx.Where("technician_id = ?", technicianID).Delete(&TimeSlot{}).Error; err != nil {
			return err
		}

		if len(slots) > 0 {
			if err := tx.Create(&slots).Error; err != nil {
				return err
			}
		}
		return nil
	})
}

func (r *repository) DeleteTechnicianSlots(ctx context.Context, technicianID uint) error {
	return r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID).
		Delete(&TimeSlot{}).Error
}
