package booking

import (
	"time"

	"changsure-core-service/internal/modules/technician"
	techService "changsure-core-service/internal/modules/technician_service"
	timeslot "changsure-core-service/internal/modules/time_slot"
)

const (
	BookingStatusPending        = "PENDING"         // รอช่างรับงาน
	BookingStatusAccepted       = "ACCEPTED"        // ช่างรับงานแล้ว
	BookingStatusInProgress     = "IN_PROGRESS"     // ช่างกำลังดำเนินการ
	BookingStatusWaitingPayment = "WAITING_PAYMENT" // รอชำระเงิน
	BookingStatusCompleted      = "COMPLETED"       // เสร็จสิ้น
	BookingStatusCancelled      = "CANCELLED"       // ยกเลิก

	PaymentMethodCOD = "COD"
)

type Booking struct {
	ID uint `gorm:"primaryKey;autoIncrement" json:"id"`

	CustomerID          uint `gorm:"not null;index" json:"-"`
	TechnicianID        uint `gorm:"not null;index" json:"technician_id"`
	TechnicianServiceID uint `gorm:"not null;index" json:"technician_service_id"`

	AddressID uint `gorm:"not null;index" json:"address_id"`

	TimeSlotID uint `gorm:"not null;index" json:"time_slot_id"`

	AppointmentDate time.Time `gorm:"type:date;not null;index" json:"appointment_date"`

	RecordedAddress string `gorm:"type:text" json:"recorded_address"`

	PriceAmount float64 `gorm:"type:decimal(10,2);not null" json:"price_amount"`

	PaymentMethod string `gorm:"type:varchar(20);default:'COD'" json:"payment_method"`
	CustomerNote  string `gorm:"type:text" json:"customer_note"`

	Status string `gorm:"type:varchar(20);default:'PENDING';index" json:"status"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	TimeSlot          timeslot.TimeSlot             `gorm:"foreignKey:TimeSlotID" json:"time_slot"`
	Technician        technician.Technician         `gorm:"foreignKey:TechnicianID" json:"technician"`
	TechnicianService techService.TechnicianService `gorm:"foreignKey:TechnicianServiceID" json:"technician_service"`

	Images []BookingImage `gorm:"foreignKey:BookingID" json:"images"`
}

type BookingImage struct {
	ID        uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	BookingID uint      `gorm:"not null;index" json:"booking_id"`
	ImageURL  string    `gorm:"type:varchar(500);not null" json:"image_url"`
	CreatedAt time.Time `json:"created_at"`
}

func (Booking) TableName() string      { return "bookings" }
func (BookingImage) TableName() string { return "booking_images" }

func Models() []interface{} {
	return []interface{}{
		&Booking{},
		&BookingImage{},
	}
}
