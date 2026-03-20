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

	LastReadByCustomer   *time.Time `gorm:"index" json:"last_read_by_customer,omitempty"`
	LastReadByTechnician *time.Time `gorm:"index" json:"last_read_by_technician,omitempty"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`

	TimeSlot          timeslot.TimeSlot             `gorm:"foreignKey:TimeSlotID" json:"time_slot"`
	Customer          customer.Customer             `gorm:"foreignKey:CustomerID" json:"customer"`
	Technician        technician.Technician         `gorm:"foreignKey:TechnicianID" json:"technician"`
	TechnicianService techService.TechnicianService `gorm:"foreignKey:TechnicianServiceID" json:"technician_service"`

	Images []BookingImage `gorm:"foreignKey:BookingID" json:"images"`

	FeeRate   *float64 `gorm:"-" json:"fee_rate,omitempty"`
	FeeAmount *float64 `gorm:"-" json:"fee_amount,omitempty"`
	NetAmount *float64 `gorm:"-" json:"net_amount,omitempty"`

	ReviewedAt *time.Time `gorm:"index" json:"reviewed_at,omitempty"`
}

type BookingImage struct {
	ID        uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	BookingID uint      `gorm:"not null;index" json:"booking_id"`
	ImageURL  string    `gorm:"type:varchar(500);not null" json:"image_url"`
	CreatedAt time.Time `json:"created_at"`
}

func (Booking) TableName() string      { return "bookings" }
func (BookingImage) TableName() string { return "booking_images" }

type Review struct {
	ID         uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	BookingID  uint      `gorm:"not null;uniqueIndex"     json:"booking_id"`
	CustomerID uint      `gorm:"not null;index"           json:"customer_id"`
	ServiceID  uint      `gorm:"not null;index"           json:"service_id"`
	Rating     int8      `gorm:"not null;check:rating >= 1 AND rating <= 5" json:"rating"`
	Comment    string    `gorm:"type:text"                json:"comment,omitempty"`
	CreatedAt  time.Time `json:"created_at"`

	Images []ReviewImage `gorm:"foreignKey:ReviewID" json:"images,omitempty"`

	CustomerName   string `gorm:"-" json:"-"`
	CustomerAvatar string `gorm:"-" json:"-"`
	ServiceName    string `gorm:"-" json:"-"`
	ServicePicture string `gorm:"-" json:"-"`
	CategoryID     uint   `gorm:"-" json:"-"`
	CategoryName   string `gorm:"-" json:"-"`
}

type ReviewImage struct {
	ID       uint   `gorm:"primaryKey;autoIncrement" json:"id"`
	ReviewID uint   `gorm:"not null;index"           json:"review_id"`
	ImageURL string `gorm:"type:varchar(500);not null" json:"image_url"`
}

func (Review) TableName() string      { return "reviews" }
func (ReviewImage) TableName() string { return "review_images" }

type ServiceRatingStat struct {
	ServiceID    uint      `gorm:"primaryKey;autoIncrement:false" json:"service_id"`
	AvgRating    float64   `gorm:"type:decimal(3,2);not null;default:0.00" json:"avg_rating"`
	TotalReviews int       `gorm:"not null;default:0" json:"total_reviews"`
	UpdatedAt    time.Time `json:"updated_at"`
}

func (ServiceRatingStat) TableName() string { return "service_rating_stats" }

type ReviewSummary struct {
	AvgRating    float64       `json:"avg_rating"`
	TotalReviews int64         `json:"total_reviews"`
	Breakdown    map[int]int64 `json:"breakdown"`
}

type ReviewFilter struct {
	Rating      *int8
	HasImages   *bool
	ServiceType *uint
}

type ReviewWithDetail struct {
	Review
	CustomerName   string `json:"customer_name"`
	CustomerAvatar string `json:"customer_avatar"`
	ServiceName    string `json:"service_name"`
	ServicePrice   string `json:"service_price"`
	ServicePicture string `json:"service_picture"`
	CategoryID     uint   `json:"category_id"`
	CategoryName   string `json:"category_name"`
}

func Models() []interface{} {
	return []interface{}{
		&Booking{},
		&BookingImage{},
		&Review{},
		&ReviewImage{},
		&ServiceRatingStat{},
	}
}
