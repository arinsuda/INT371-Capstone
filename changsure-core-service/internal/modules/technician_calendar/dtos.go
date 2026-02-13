package techniciancalendar

import (
	"fmt"
	"regexp"
	"time"
)

// ===========================
// Query DTOs
// ===========================

type CalendarQuery struct {
	TechnicianID uint   `query:"technician_id" validate:"required,min=1"`
	Month        string `query:"month" validate:"required,len=7"`
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

// ParseMonth แปลง month string เป็น time.Time (วันแรกของเดือน)
func (q *CalendarQuery) ParseMonth() (time.Time, error) {
	return time.Parse("2006-01", q.Month)
}

// ===========================
// Request DTOs
// ===========================

type UpdateCalendarDateRequest struct {
	Date   string `json:"date" validate:"required"`
	IsOpen bool   `json:"is_open"`
}

func (r *UpdateCalendarDateRequest) Validate() error {
	if !isValidDateFormat(r.Date) {
		return fmt.Errorf("date must be in YYYY-MM-DD format")
	}

	if _, err := time.Parse("2006-01-02", r.Date); err != nil {
		return fmt.Errorf("invalid date value: %w", err)
	}

	return nil
}

// ParseDate แปลง date string เป็น time.Time
func (r *UpdateCalendarDateRequest) ParseDate() (time.Time, error) {
	return time.Parse("2006-01-02", r.Date)
}

type UpdateTimeSlotsRequest struct {
	Month       string `query:"month" json:"-"`
	TimeSlotIDs []uint `json:"time_slot_ids" validate:"required,min=0"`
	IsDefault   bool   `json:"is_default"`
}

func (r *UpdateTimeSlotsRequest) Validate() error {
	// ถ้าเป็น default config ไม่ต้องมี month
	if r.IsDefault {
		return nil
	}

	// ถ้าไม่ใช่ default ต้องมี month
	if r.Month == "" {
		return fmt.Errorf("month parameter is required when is_default is false")
	}

	// รองรับทั้ง YYYY-MM-DD และ YYYY-MM
	if !isValidDateFormat(r.Month) && !isValidMonthFormat(r.Month) {
		return fmt.Errorf("month must be in YYYY-MM-DD or YYYY-MM format")
	}

	return nil
}

// ParseDate แปลง month parameter เป็น time.Time
// รองรับทั้ง YYYY-MM-DD และ YYYY-MM format
func (r *UpdateTimeSlotsRequest) ParseDate() (time.Time, error) {
	// ลอง parse YYYY-MM-DD ก่อน
	if date, err := time.Parse("2006-01-02", r.Month); err == nil {
		return normalizeDate(date), nil
	}

	// ถ้าไม่ได้ ลอง YYYY-MM
	if date, err := time.Parse("2006-01", r.Month); err == nil {
		// ใช้วันที่ 1 ของเดือน
		return normalizeDate(date), nil
	}

	return time.Time{}, fmt.Errorf("invalid date format: %s", r.Month)
}

// ===========================
// Response DTOs
// ===========================

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

// ===========================
// Enums
// ===========================

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

// ===========================
// Helper Functions
// ===========================

var (
	dateRegex  = regexp.MustCompile(`^\d{4}-\d{2}-\d{2}$`)
	monthRegex = regexp.MustCompile(`^\d{4}-(0[1-9]|1[0-2])$`)
)

// isValidDateFormat ตรวจสอบ format YYYY-MM-DD
func isValidDateFormat(s string) bool {
	return dateRegex.MatchString(s)
}

// isValidMonthFormat ตรวจสอบ format YYYY-MM
func isValidMonthFormat(s string) bool {
	return monthRegex.MatchString(s)
}

// normalizeDate ปรับ time.Time ให้เป็น midnight UTC
func normalizeDate(t time.Time) time.Time {
	return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC)
}

// getTodayMidnight คืนค่าวันนี้เวลา 00:00:00 UTC
func getTodayMidnight() time.Time {
	return normalizeDate(time.Now())
}

// isPastDate ตรวจสอบว่าเป็นวันที่ผ่านมาแล้วหรือไม่
func isPastDate(date time.Time) bool {
	return normalizeDate(date).Before(getTodayMidnight())
}
