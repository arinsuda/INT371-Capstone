package technicianschedule

import (
	"context"

	"gorm.io/gorm"
)

type Repository interface {
	UpdateWeeklySchedule(ctx context.Context, techID uint, workingDays []int) error
	GetWeeklySchedule(ctx context.Context, techID uint) ([]int, error)

	AddLeaveDate(ctx context.Context, leave *LeaveDate) error
	RemoveLeaveDate(ctx context.Context, techID uint, dateStr string) error
	GetLeavesByRange(ctx context.Context, techID uint, startDate, endDate string) (map[string]bool, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) UpdateWeeklySchedule(ctx context.Context, techID uint, workingDays []int) error {
	return r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {

		if err := tx.Where("technician_id = ?", techID).Delete(&WeeklySchedule{}).Error; err != nil {
			return err
		}

		if len(workingDays) > 0 {
			schedules := make([]WeeklySchedule, len(workingDays))
			for i, day := range workingDays {
				schedules[i] = WeeklySchedule{
					TechnicianID: techID,
					DayOfWeek:    day,
					IsWorking:    true,
				}
			}
			if err := tx.Create(&schedules).Error; err != nil {
				return err
			}
		}
		return nil
	})
}

func (r *repository) GetWeeklySchedule(ctx context.Context, techID uint) ([]int, error) {
	var days []int
	err := r.db.WithContext(ctx).
		Model(&WeeklySchedule{}).
		Where("technician_id = ? AND is_working = ?", techID, true).
		Pluck("day_of_week", &days).Error
	return days, err
}

func (r *repository) AddLeaveDate(ctx context.Context, leave *LeaveDate) error {

	return r.db.WithContext(ctx).
		Where(LeaveDate{TechnicianID: leave.TechnicianID, Date: leave.Date}).
		Assign(LeaveDate{Reason: leave.Reason}).
		FirstOrCreate(leave).Error
}

func (r *repository) RemoveLeaveDate(ctx context.Context, techID uint, dateStr string) error {
	return r.db.WithContext(ctx).
		Where("technician_id = ? AND date = ?", techID, dateStr).
		Delete(&LeaveDate{}).Error
}

func (r *repository) GetLeavesByRange(ctx context.Context, techID uint, startDate, endDate string) (map[string]bool, error) {
	var leaves []LeaveDate
	err := r.db.WithContext(ctx).
		Where("technician_id = ? AND date BETWEEN ? AND ?", techID, startDate, endDate).
		Find(&leaves).Error

	if err != nil {
		return nil, err
	}

	result := make(map[string]bool)
	for _, l := range leaves {
		result[l.Date.Format("2006-01-02")] = true
	}
	return result, nil
}
