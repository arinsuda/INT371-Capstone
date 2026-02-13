package techniciancalendar

import (
	"fmt"
	"regexp"
	"time"

	"changsure-core-service/internal/modules/booking"
)

type CalendarQuery struct {
	TechnicianID uint   `query:"technician_id" validate:"required,min=1"`
	Month        string `query:"month" validate:"required,len=7"`
}

type CalendarDayQuery struct {
	TechnicianID uint   `query:"technician_id"`
	Date         string `query:"date"`
	TimeSlotID   *uint  `query:"timeslot"`
}

func (q *CalendarQuery) Validate() error {
	if q.TechnicianID == 0 {
		return fmt.Errorf("technician_id must be greater than 0")
	}

	if !isValidMonthFormat(q.Month) {
		return fmt.Errorf("month must be in YYYY-MM format")
	}

	if _, err := time.Parse("2006-01", q.Month); err != nil {
		return fmt.Errorf("invalid month value: %w", err)
	}

	return nil
}

func (q *CalendarQuery) ParseMonth() (time.Time, error) {

	t, err := time.ParseInLocation("2006-01", q.Month, booking.BKKLocation)
	if err != nil {
		return time.Time{}, err
	}
	return booking.NormalizeDate(t), nil
}

type UpdateCalendarDateRequest struct {
	Date   string `json:"date" validate:"required"`
	IsOpen bool   `json:"is_open"`
}

func (r *UpdateCalendarDateRequest) Validate() error {
	if !isValidDateFormat(r.Date) {
		return fmt.Errorf("date must be in YYYY-MM-DD format")
	}

	if _, err := booking.ParseDate(r.Date); err != nil {
		return fmt.Errorf("invalid date value: %w", err)
	}

	return nil
}

func (r *UpdateCalendarDateRequest) ParseDate() (time.Time, error) {
	return booking.ParseDate(r.Date)
}

type UpdateTimeSlotsRequest struct {
	Date        string `query:"date" json:"-"`
	TimeSlotIDs []uint `json:"time_slot_ids" validate:"required,min=0"`
	IsDefault   bool   `json:"is_default"`
}

func (r *UpdateTimeSlotsRequest) Validate() error {
	if r.IsDefault {
		if len(r.TimeSlotIDs) == 0 {
			return fmt.Errorf("time_slot_ids is required")
		}
		return nil
	}

	if r.Date == "" {
		return fmt.Errorf("date parameter is required when is_default is false")
	}

	if !isValidDateFormat(r.Date) {
		return fmt.Errorf("date must be in YYYY-MM-DD format")
	}

	if len(r.TimeSlotIDs) == 0 {
		return fmt.Errorf("time_slot_ids is required")
	}

	return nil
}

func (r *UpdateTimeSlotsRequest) ParseDate() (time.Time, error) {
	if r.IsDefault {
		return time.Now(), nil
	}

	date, err := booking.ParseDate(r.Date)
	if err != nil {
		return time.Time{}, fmt.Errorf("invalid date format: %s", r.Date)
	}

	return booking.NormalizeDate(date), nil
}

type CalendarResponse struct {
	Month string              `json:"month"`
	Days  []CalendarDayStatus `json:"days"`
}

type CalendarDayStatus struct {
	Date           string           `json:"date"`
	Status         DayStatus        `json:"status"`
	TotalSlots     int              `json:"total_slots"`
	BookedSlots    int              `json:"booked_slots"`
	AvailableSlots int              `json:"available_slots"`
	TimeSlots      []TimeSlotDetail `json:"time_slots"`
	Bookings       []BookingDetail  `json:"bookings"`
}

type BookingDetail struct {
	ID              uint     `json:"id"`
	BookingNumber   string   `json:"booking_number"`
	TimeSlotID      uint     `json:"time_slot_id"`
	ServiceName     string   `json:"service_name"`
	PricingType     string   `json:"pricing_type"`
	QuotedPrice     *float64 `json:"quoted_price,omitempty"`
	QuotedPriceMin  *float64 `json:"quoted_price_min,omitempty"`
	QuotedPriceMax  *float64 `json:"quoted_price_max,omitempty"`
	FinalPrice      *float64 `json:"final_price,omitempty"`
	AppointmentDate string   `json:"appointment_date"`
	Status          string   `json:"status"`
	CustomerID      uint     `json:"customer_id"`
	CustomerName    string   `json:"customer_name"`
	CustomerPhone   string   `json:"customer_phone"`
	CustomerAvatar  string   `json:"customer_avatar"`
	Images          []string `json:"images"`
}

type UpdateCalendarDateResponse struct {
	Date   string `json:"date"`
	IsOpen bool   `json:"is_open"`
}

type UpdateTimeSlotsResponse struct {
	Date      string           `json:"date"`
	IsDefault bool             `json:"is_default"`
	TimeSlots []TimeSlotDetail `json:"time_slots"`
}

type TimeSlotDetail struct {
	ID        uint   `json:"id"`
	TimeRange string `json:"time_range"`
	IsBooked  bool   `json:"is_booked"`
}

type DayStatus string

const (
	DayStatusAvailable DayStatus = "AVAILABLE"
	DayStatusFull      DayStatus = "FULL"
	DayStatusClosed    DayStatus = "CLOSED"
)

func (d DayStatus) String() string {
	return string(d)
}

func (d DayStatus) IsValid() bool {
	switch d {
	case DayStatusAvailable, DayStatusFull, DayStatusClosed:
		return true
	default:
		return false
	}
}

var (
	dateRegex  = regexp.MustCompile(`^\d{4}-\d{2}-\d{2}$`)
	monthRegex = regexp.MustCompile(`^\d{4}-(0[1-9]|1[0-2])$`)
)

func isValidDateFormat(s string) bool {
	return dateRegex.MatchString(s)
}

func isValidMonthFormat(s string) bool {
	return monthRegex.MatchString(s)
}
