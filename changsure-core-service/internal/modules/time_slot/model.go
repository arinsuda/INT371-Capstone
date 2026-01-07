package timeslot

import (
	"time"

	"gorm.io/gorm"
)

type TimeSlot struct {
	ID uint `gorm:"primaryKey" json:"id"`

	TechnicianID *uint `gorm:"index" json:"technician_id,omitempty"`

	StartTime string `gorm:"type:varchar(5);not null;comment:Format HH:mm" json:"start_time"`
	EndTime   string `gorm:"type:varchar(5);not null;comment:Format HH:mm" json:"end_time"`
	IsActive  bool   `gorm:"default:true" json:"is_active"`

	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

func (TimeSlot) TableName() string {
	return "time_slots"
}

func Models() []interface{} {
	return []interface{}{
		&TimeSlot{},
	}
}

type TimeSlotResponse struct {
	ID          uint   `json:"id"`
	StartTime   string `json:"start_time"`
	EndTime     string `json:"end_time"`
	DisplayText string `json:"display_text"`
}
