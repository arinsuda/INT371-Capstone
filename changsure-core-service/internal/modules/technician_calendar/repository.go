package techniciancalendar

import (
	"context"
	"time"

	"changsure-core-service/internal/modules/booking"

	"gorm.io/gorm"
)

type Repository interface {
	SetClosedDate(ctx context.Context, technicianID uint, date time.Time, isClosed bool) error
	GetClosedDatesByRange(
		ctx context.Context,
		technicianID uint,
		startDate, endDate time.Time,
	) (map[string]bool, error)
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

func (r *repository) SetClosedDate(ctx context.Context, technicianID uint, date time.Time, isClosed bool) error {

	cleanDate := booking.NormalizeDate(date)

	if !isClosed {

		return r.db.WithContext(ctx).
			Where("technician_id = ? AND date = ?", technicianID, cleanDate).
			Delete(&TechnicianClosedDate{}).Error
	}

	return r.db.WithContext(ctx).
		Where(TechnicianClosedDate{
			TechnicianID: technicianID,
			Date:         cleanDate,
		}).
		FirstOrCreate(&TechnicianClosedDate{}).Error
}

func (r *repository) GetClosedDatesByRange(
	ctx context.Context,
	technicianID uint,
	startDate, endDate time.Time,
) (map[string]bool, error) {

	startNorm := booking.NormalizeDate(startDate)
	endNorm := booking.NormalizeDate(endDate)

	startStr := booking.FormatDate(startNorm)
	endStr := booking.FormatDate(endNorm)

	rows, err := r.db.WithContext(ctx).
		Model(&TechnicianClosedDate{}).
		Select("date").
		Where("technician_id = ?", technicianID).
		Where("date BETWEEN ? AND ?", startStr, endStr).
		Rows()

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	result := make(map[string]bool, 16)

	for rows.Next() {
		var d time.Time
		if err := rows.Scan(&d); err != nil {
			return nil, err
		}

		result[booking.FormatDate(d)] = true
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

	normalizedDate := booking.NormalizeDate(date)

	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		if err := tx.Where("technician_id = ? AND date = ?", technicianID, normalizedDate).
			Delete(&TechnicianDateTimeSlot{}).Error; err != nil {
			return err
		}

		if len(timeSlotIDs) > 0 {
			slots := make([]TechnicianDateTimeSlot, len(timeSlotIDs))
			for i, slotID := range timeSlotIDs {
				slots[i] = TechnicianDateTimeSlot{
					TechnicianID: technicianID,
					Date:         &normalizedDate,
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

	normalizedDate := booking.NormalizeDate(date)

	return r.db.WithContext(ctx).
		Where("technician_id = ? AND date = ?", technicianID, normalizedDate).
		Delete(&TechnicianDateTimeSlot{}).Error
}

func (r *repository) GetTimeSlotsForDate(ctx context.Context, technicianID uint, date *time.Time) ([]uint, error) {
	var slots []TechnicianDateTimeSlot

	query := r.db.WithContext(ctx).
		Where("technician_id = ?", technicianID)

	if date == nil {

		query = query.Where("date IS NULL")
	} else {

		normalizedDate := booking.NormalizeDate(*date)
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

	startNorm := booking.NormalizeDate(startDate)
	endNorm := booking.NormalizeDate(endDate)

	endNorm = time.Date(endNorm.Year(), endNorm.Month(), endNorm.Day(), 23, 59, 59, 0, booking.BKKLocation)

	var slots []TechnicianDateTimeSlot

	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND (date IS NULL OR date BETWEEN ? AND ?)",
			technicianID, startNorm, endNorm).
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

			dateKey := booking.FormatDate(*slot.Date)
			result[dateKey] = append(result[dateKey], slot.TimeSlotID)
		}
	}

	if len(defaultSlots) > 0 {
		result["__default__"] = defaultSlots
	}

	return result, nil
}
