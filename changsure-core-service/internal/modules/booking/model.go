package booking

import (
	"time"

	customer "changsure-core-service/internal/modules/customer"
	"changsure-core-service/internal/modules/technician"
	techService "changsure-core-service/internal/modules/technician_service"
	timeslot "changsure-core-service/internal/modules/time_slot"
)

type Booking struct {
	ID uint `gorm:"primaryKey;autoIncrement" json:"id"`

	BookingNumber string `gorm:"type:varchar(10);uniqueIndex;not null" json:"booking_number"`

	CustomerID          uint `gorm:"not null;index" json:"-"`
	TechnicianID        uint `gorm:"not null;index" json:"technician_id"`
	TechnicianServiceID uint `gorm:"not null;index" json:"technician_service_id"`

	AddressID uint `gorm:"not null;index" json:"address_id"`

	TimeSlotID uint `gorm:"not null;index" json:"time_slot_id"`

	AppointmentDate time.Time `gorm:"type:date;not null;index" json:"appointment_date"`

	RecordedAddress string `gorm:"type:text" json:"recorded_address"`

	PricingType string `gorm:"type:enum('FIXED','RANGE');not null" json:"pricing_type"`

	QuotedPriceFixed *float64 `gorm:"type:decimal(12,2)" json:"quoted_price_fixed"`
	QuotedPriceMin   *float64 `gorm:"type:decimal(12,2)" json:"quoted_price_min"`
	QuotedPriceMax   *float64 `gorm:"type:decimal(12,2)" json:"quoted_price_max"`

	PaymentMethod string `gorm:"type:varchar(20);default:'COD'" json:"payment_method"`
	CustomerNote  string `gorm:"type:text" json:"customer_note"`

	FinalPrice *float64 `gorm:"type:decimal(12,2)" json:"final_price"`

	Status string `gorm:"type:varchar(20);default:'PENDING';index" json:"status"`

	// Chat tracking - when each party last read the chat
	LastReadByCustomer   *time.Time `gorm:"index" json:"last_read_by_customer,omitempty"`
	LastReadByTechnician *time.Time `gorm:"index" json:"last_read_by_technician,omitempty"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	TimeSlot          timeslot.TimeSlot             `gorm:"foreignKey:TimeSlotID" json:"time_slot"`
	Customer          customer.Customer             `gorm:"foreignKey:CustomerID" json:"customer"`
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
