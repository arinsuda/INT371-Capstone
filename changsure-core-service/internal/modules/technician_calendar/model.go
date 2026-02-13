package techniciancalendar

import (
	"time"

	"gorm.io/gorm"
)

type TechnicianClosedDate struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	TechnicianID uint           `gorm:"index:idx_tech_date,priority:1;not null" json:"technician_id"`
	Date         time.Time      `gorm:"type:date;index:idx_tech_date,priority:2;not null" json:"date"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

type TechnicianDateTimeSlot struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	TechnicianID uint           `gorm:"index:idx_tech_date_slot,priority:1;not null" json:"technician_id"`
	Date         *time.Time     `gorm:"type:date;index:idx_tech_date_slot,priority:2" json:"date,omitempty"`
	TimeSlotID   uint           `gorm:"not null" json:"time_slot_id"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

func (TechnicianClosedDate) TableName() string {
	return "technician_closed_dates"
}

func (TechnicianDateTimeSlot) TableName() string {
	return "technician_date_time_slots"
}

func Models() []interface{} {
	return []interface{}{
		&TechnicianClosedDate{},
		&TechnicianDateTimeSlot{},
	}
}
