package techniciancalendar

import (
	"time"

	"gorm.io/gorm"
)

// TechnicianCalendarDate - เก็บสถานะเปิด/ปิดของแต่ละวัน
type TechnicianCalendarDate struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	TechnicianID uint           `gorm:"index:idx_tech_date,priority:1;not null" json:"technician_id"`
	Date         time.Time      `gorm:"type:date;index:idx_tech_date,priority:2;not null" json:"date"`
	IsOpen       bool           `gorm:"default:true;not null" json:"is_open"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

// TechnicianDateTimeSlot - เก็บ time slots ที่เลือกสำหรับแต่ละวัน
// ถ้า Date = NULL หมายถึง default slots สำหรับทุกวัน
type TechnicianDateTimeSlot struct {
	ID           uint           `gorm:"primaryKey" json:"id"`
	TechnicianID uint           `gorm:"index:idx_tech_date_slot,priority:1;not null" json:"technician_id"`
	Date         *time.Time     `gorm:"type:date;index:idx_tech_date_slot,priority:2" json:"date,omitempty"`
	TimeSlotID   uint           `gorm:"not null" json:"time_slot_id"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index" json:"-"`
}

type TechnicianClosedDate struct {
	ID           uint   `gorm:"primaryKey"`
	TechnicianID uint   `gorm:"uniqueIndex:idx_tech_date"`
	Date         string `gorm:"type:date;uniqueIndex:idx_tech_date"`
	CreatedAt    time.Time
}

func (TechnicianCalendarDate) TableName() string {
	return "technician_calendar_dates"
}

func (TechnicianDateTimeSlot) TableName() string {
	return "technician_date_time_slots"
}

func Models() []interface{} {
	return []interface{}{
		&TechnicianCalendarDate{},
		&TechnicianDateTimeSlot{},
	}
}
