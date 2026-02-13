package techniciancalendar

import (
	"context"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Repository interface {
	UpsertCalendarDate(ctx context.Context, technicianID uint, date time.Time, isOpen bool) error
	GetCalendarDatesByRange(ctx context.Context, technicianID uint, startDate, endDate time.Time) (map[string]bool, error)

	SetDefaultTimeSlots(ctx context.Context, technicianID uint, timeSlotIDs []uint) error
	SetDateTimeSlots(ctx context.Context, technicianID uint, date time.Time, timeSlotIDs []uint) error
	DeleteDateTimeSlots(ctx context.Context, technicianID uint, date time.Time) error
	GetTimeSlotsForDate(ctx context.Context, technicianID uint, date *time.Time) ([]uint, error)
	GetTimeSlotsForMonth(ctx context.Context, technicianID uint, startDate, endDate time.Time) (map[string][]uint, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

// 📂 internal/modules/technician_calendar/repository.go

func (r *repository) UpsertCalendarDate(ctx context.Context, technicianID uint, date time.Time, isOpen bool) error {
	// Best Practice: บังคับให้เป็น UTC และตัดเศษวินาทีทิ้งให้หมด
	cleanDate := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if isOpen {
			return tx.
				Where("technician_id = ? AND date = ?", technicianID, cleanDate).
				Delete(&TechnicianCalendarDate{}).Error
		}

		return tx.Clauses(clause.OnConflict{
			Columns:   []clause.Column{{Name: "technician_id"}, {Name: "date"}},
			DoUpdates: clause.AssignmentColumns([]string{"is_open", "updated_at"}),
		}).Create(&TechnicianCalendarDate{
			TechnicianID: technicianID,
			Date:         cleanDate,
			IsOpen:       false,
		}).Error

	})
}

func (r *repository) GetCalendarDatesByRange(ctx context.Context, technicianID uint, startDate, endDate time.Time) (map[string]bool, error) {
	// Normalize dates
	startDate = time.Date(startDate.Year(), startDate.Month(), startDate.Day(), 0, 0, 0, 0, time.UTC)
	endDate = time.Date(endDate.Year(), endDate.Month(), endDate.Day(), 23, 59, 59, 0, time.UTC)

	var dates []TechnicianCalendarDate

	// ✅ Explicitly exclude soft-deleted records
	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND date BETWEEN ? AND ? AND deleted_at IS NULL",
			technicianID, startDate, endDate).
		Find(&dates).Error

	if err != nil {
		return nil, err
	}

	result := make(map[string]bool)
	for _, d := range dates {
		dateKey := d.Date.Format("2006-01-02")
		result[dateKey] = d.IsOpen
	}

	return result, nil
}

func (r *repository) SetDefaultTimeSlots(ctx context.Context, technicianID uint, timeSlotIDs []uint) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		if err := tx.Where("technician_id = ? AND date IS NULL", technicianID).
			Delete(&TechnicianDateTimeSlot{}).Error; err != nil {
			return err
		}

		if len(timeSlotIDs) > 0 {
			slots := make([]TechnicianDateTimeSlot, len(timeSlotIDs))
			for i, slotID := range timeSlotIDs {
				slots[i] = TechnicianDateTimeSlot{
					TechnicianID: technicianID,
					Date:         nil,
					TimeSlotID:   slotID,
				}
			}
			if err := tx.Create(&slots).Error; err != nil {
				return err
			}
		}

		return nil
	})
}

func (r *repository) SetDateTimeSlots(ctx context.Context, technicianID uint, date time.Time, timeSlotIDs []uint) error {
	// Normalize date
	date = time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		if err := tx.Where("technician_id = ? AND date = ?", technicianID, date).
			Delete(&TechnicianDateTimeSlot{}).Error; err != nil {
			return err
		}

		if len(timeSlotIDs) > 0 {
			slots := make([]TechnicianDateTimeSlot, len(timeSlotIDs))
			for i, slotID := range timeSlotIDs {
				slots[i] = TechnicianDateTimeSlot{
					TechnicianID: technicianID,
					Date:         &date,
					TimeSlotID:   slotID,
				}
			}
			if err := tx.Create(&slots).Error; err != nil {
				return err
			}
		}

		return nil
	})
}

func (r *repository) DeleteDateTimeSlots(ctx context.Context, technicianID uint, date time.Time) error {
	// Normalize date
	date = time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)

	return r.db.WithContext(ctx).
		Where("technician_id = ? AND date = ?", technicianID, date).
		Delete(&TechnicianDateTimeSlot{}).Error
}

func (r *repository) GetTimeSlotsForDate(ctx context.Context, technicianID uint, date *time.Time) ([]uint, error) {
	var slots []TechnicianDateTimeSlot

	query := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID)

	if date == nil {

		query = query.Where("date IS NULL")
	} else {
		// Normalize date
		normalizedDate := time.Date(date.Year(), date.Month(), date.Day(), 0, 0, 0, 0, time.UTC)
		query = query.Where("date = ?", normalizedDate)
	}

	if err := query.Find(&slots).Error; err != nil {
		return nil, err
	}

	slotIDs := make([]uint, len(slots))
	for i, slot := range slots {
		slotIDs[i] = slot.TimeSlotID
	}

	return slotIDs, nil
}

func (r *repository) GetTimeSlotsForMonth(ctx context.Context, technicianID uint, startDate, endDate time.Time) (map[string][]uint, error) {
	// Normalize dates
	startDate = time.Date(startDate.Year(), startDate.Month(), startDate.Day(), 0, 0, 0, 0, time.UTC)
	endDate = time.Date(endDate.Year(), endDate.Month(), endDate.Day(), 23, 59, 59, 0, time.UTC)

	var slots []TechnicianDateTimeSlot

	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND (date IS NULL OR date BETWEEN ? AND ?)",
			technicianID, startDate, endDate).
		Find(&slots).Error

	if err != nil {
		return nil, err
	}

	result := make(map[string][]uint)
	var defaultSlots []uint

	for _, slot := range slots {
		if slot.Date == nil {

			defaultSlots = append(defaultSlots, slot.TimeSlotID)
		} else {

			dateKey := slot.Date.Format("2006-01-02")
			result[dateKey] = append(result[dateKey], slot.TimeSlotID)
		}
	}

	if len(defaultSlots) > 0 {
		result["__default__"] = defaultSlots
	}

	return result, nil
}
