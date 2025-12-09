package reservation

import "time"

type Reservation struct {
	ID                   uint      `gorm:"primaryKey;autoIncrement"`
	CustomerID           uint      `gorm:"not null;index:idx_resv_customer_status,priority:1"`
	TechnicianID         uint      `gorm:"not null;index:idx_resv_technician_status,priority:1"`
	ServiceID            uint      `gorm:"not null"`
	StartAt              time.Time `gorm:"not null;index:idx_reservations_start_at;index:idx_resv_time,priority:2"`
	EndAt                time.Time `gorm:"not null;index:idx_resv_time,priority:3"`
	Timezone             string    `gorm:"type:varchar(50);not null;default:'Asia/Bangkok'"`
	StatusID             uint      `gorm:"not null;default:1;index:idx_resv_status"`
	ConfirmationDeadline time.Time `gorm:"not null"`
	Address              string    `gorm:"type:varchar(500);not null"`
	ProvinceID           *uint     `gorm:"index"`
	Latitude             *float64  `gorm:"type:decimal(10,7)"`
	Longitude            *float64  `gorm:"type:decimal(10,7)"`
	PriceEstimate        *float64  `gorm:"type:decimal(12,2)"`
	PriceFinal           *float64  `gorm:"type:decimal(12,2)"`
	Notes                *string   `gorm:"type:text"`
	CreatedAt            time.Time `gorm:"autoCreateTime"`
	UpdatedAt            time.Time `gorm:"autoUpdateTime"`
}

func (Reservation) TableName() string { return "reservations" }

type ReservationStatusLog struct {
	ID            uint      `gorm:"primaryKey;autoIncrement"`
	ReservationID uint      `gorm:"index:idx_resvlog_time,priority:1;index:idx_resvlog_status,priority:1"`
	OldStatusID   *uint
	NewStatusID   uint      `gorm:"index:idx_resvlog_status,priority:2"`
	ChangedAt     time.Time `gorm:"autoCreateTime"`
}

func (ReservationStatusLog) TableName() string { return "reservation_status_logs" }

func Models() []interface{} {
	return []interface{}{
		&Reservation{},
		&ReservationStatusLog{},
	}
}
