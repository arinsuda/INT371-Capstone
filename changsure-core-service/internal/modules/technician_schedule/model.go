package technicianschedule

import (
	"time"
)

type WeeklySchedule struct {
	ID           uint `gorm:"primaryKey" json:"id"`
	TechnicianID uint `gorm:"index;not null" json:"-"`

	DayOfWeek int  `gorm:"not null" json:"day_of_week"`
	IsWorking bool `gorm:"default:false" json:"is_working"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type LeaveDate struct {
	ID           uint      `gorm:"primaryKey" json:"id"`
	TechnicianID uint      `gorm:"index;not null" json:"-"`
	Date         time.Time `gorm:"type:date;index;not null" json:"date"`
	Reason       string    `gorm:"type:text" json:"reason"`

	CreatedAt time.Time `json:"created_at"`
}

func (WeeklySchedule) TableName() string { return "technician_weekly_schedules" }
func (LeaveDate) TableName() string      { return "technician_leave_dates" }

func Models() []interface{} {
	return []interface{}{
		&WeeklySchedule{},
		&LeaveDate{},
	}
}
