package techniciancalendar

import (
	"time"

	timeslot "changsure-core-service/internal/modules/time_slot"
)

// ===========================
// Domain Models
// ===========================

// DateRange represents a time period
type DateRange struct {
	Start time.Time
	End   time.Time
}

// CalendarData aggregates all data needed to build calendar
type CalendarData struct {
	CalendarDates map[string]bool          // date -> isOpen
	TimeSlots     map[string][]uint        // date -> slotIDs (includes "__default__")
	AllTimeSlots  []timeslot.TimeSlot      // system time slots
	Bookings      map[string]map[uint]bool // date -> slotID -> isBooked
}

// BookingInfo minimal booking info for calendar
type BookingInfo struct {
	Date       time.Time
	TimeSlotID uint
}

// ===========================
// Date & Time Helpers
// ===========================

// CalculateMonthRange คำนวณวันแรกและวันสุดท้ายของเดือน
func CalculateMonthRange(monthStart time.Time) DateRange {
	year, month, _ := monthStart.Date()
	firstOfMonth := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	lastOfMonth := firstOfMonth.AddDate(0, 1, -1)

	return DateRange{
		Start: firstOfMonth,
		End:   lastOfMonth,
	}
}

// ===========================
// Data Transformation Helpers
// ===========================

// BuildBookingMap สร้าง map สำหรับ lookup การจองอย่างรวดเร็ว
// Input: []BookingInfo
// Output: map[date]map[slotID]bool
func BuildBookingMap(bookings []BookingInfo) map[string]map[uint]bool {
	bookingMap := make(map[string]map[uint]bool)

	for _, b := range bookings {
		dateKey := b.Date.Format("2006-01-02")
		if _, exists := bookingMap[dateKey]; !exists {
			bookingMap[dateKey] = make(map[uint]bool)
		}
		bookingMap[dateKey][b.TimeSlotID] = true
	}

	return bookingMap
}

// BuildTimeSlotMap สร้าง map สำหรับ lookup time slot details
// Input: []timeslot.TimeSlot
// Output: map[slotID]TimeSlot
func BuildTimeSlotMap(slots []timeslot.TimeSlot) map[uint]timeslot.TimeSlot {
	slotMap := make(map[uint]timeslot.TimeSlot)
	for _, slot := range slots {
		slotMap[slot.ID] = slot
	}
	return slotMap
}

// ===========================
// Business Logic Helpers
// ===========================

// ResolveSlotIDs หา slot IDs ที่ใช้สำหรับวันนั้น
// ลำดับความสำคัญ: Date-specific > Default > System All
//
// Example:
//   - วันที่ 15 มี config เฉพาะ -> ใช้ config วันที่ 15
//   - วันที่ 16 ไม่มี config -> ใช้ default ของช่าง
//   - ถ้าไม่มี default -> ใช้ system slots ทั้งหมด
func ResolveSlotIDs(dateStr string, data *CalendarData) []uint {
	// 1. Date-specific configuration (highest priority)
	if specificSlots, ok := data.TimeSlots[dateStr]; ok && len(specificSlots) > 0 {
		return specificSlots
	}

	// 2. Technician's default configuration
	if defaultSlots, ok := data.TimeSlots["__default__"]; ok && len(defaultSlots) > 0 {
		return defaultSlots
	}

	// 3. System default (all active slots)
	systemSlotIDs := make([]uint, len(data.AllTimeSlots))
	for i, slot := range data.AllTimeSlots {
		systemSlotIDs[i] = slot.ID
	}
	return systemSlotIDs
}

// CalculateDayStatus คำนวณสถานะของวัน
// CLOSED: ไม่มี slot
// FULL: จองเต็มหมดแล้ว
// AVAILABLE: มี slot ว่าง
func CalculateDayStatus(totalSlots, bookedSlots int) DayStatus {
	if totalSlots == 0 {
		return DayStatusClosed
	}
	if bookedSlots >= totalSlots {
		return DayStatusFull
	}
	return DayStatusAvailable
}

// IsDateClosed ตรวจสอบว่าวันนั้นปิดหรือไม่
// - ถ้าไม่มีในระบบ = เปิด (default)
// - ถ้ามีและ isOpen = false = ปิด
func IsDateClosed(dateStr string, calendarDates map[string]bool) bool {
	isOpen, exists := calendarDates[dateStr]
	// ถ้าไม่มีข้อมูล = เปิด (default)
	// ถ้ามีข้อมูลแล้วเป็น false = ปิด
	return exists && !isOpen
}

// ===========================
// UI Building Helpers
// ===========================

// CreateClosedDay สร้าง CalendarDayStatus สำหรับวันที่ปิด
func CreateClosedDay(dateStr string) CalendarDayStatus {
	return CalendarDayStatus{
		Date:           dateStr,
		Status:         DayStatusClosed,
		TotalSlots:     0,
		BookedSlots:    0,
		AvailableSlots: 0,
		TimeSlots:      []TimeSlotDetail{},
	}
}

// BuildSlotDetails สร้าง TimeSlotDetail array พร้อมข้อมูลการจอง
//
// Parameters:
//   - slotIDs: รายการ slot IDs ที่ต้องการ
//   - slotMap: map ของ time slot details
//   - bookedSlots: map ของ slots ที่ถูกจองแล้ว
//
// Returns:
//   - []TimeSlotDetail: รายการ slots พร้อมข้อมูลการจอง
func BuildSlotDetails(
	slotIDs []uint,
	slotMap map[uint]timeslot.TimeSlot,
	bookedSlots map[uint]bool,
) []TimeSlotDetail {
	details := make([]TimeSlotDetail, 0, len(slotIDs))

	for _, slotID := range slotIDs {
		slot, ok := slotMap[slotID]
		if !ok {
			// Skip invalid slot IDs
			continue
		}

		isBooked := bookedSlots[slotID]
		details = append(details, TimeSlotDetail{
			ID:        slot.ID,
			TimeRange: FormatTimeRange(slot.StartTime, slot.EndTime),
			IsBooked:  isBooked,
		})
	}

	return details
}

// FormatTimeRange format time range string
// Example: "09:00", "10:00" -> "09:00 - 10:00"
func FormatTimeRange(start, end string) string {
	return start + " - " + end
}

// CountBookedSlots นับจำนวน slot ที่ถูกจอง
func CountBookedSlots(slots []TimeSlotDetail) int {
	count := 0
	for _, slot := range slots {
		if slot.IsBooked {
			count++
		}
	}
	return count
}

// ===========================
// Validation Helpers
// ===========================

// ValidateSlotIDs ตรวจสอบว่า slot IDs ทั้งหมดมีอยู่ในระบบ
//
// Parameters:
//   - slotIDs: รายการ slot IDs ที่ต้องการตรวจสอบ
//   - validSlots: map ของ valid slot IDs
//
// Returns:
//   - error: ErrTimeSlotNotFound ถ้ามี slot ID ไม่ถูกต้อง
func ValidateSlotIDs(slotIDs []uint, validSlots map[uint]bool) error {
	for _, slotID := range slotIDs {
		if !validSlots[slotID] {
			return ErrTimeSlotNotFound
		}
	}
	return nil
}

// BuildValidSlotMap สร้าง map ของ valid slot IDs
// ใช้สำหรับ validation อย่างรวดเร็ว
func BuildValidSlotMap(slots []timeslot.TimeSlot) map[uint]bool {
	validMap := make(map[uint]bool)
	for _, slot := range slots {
		validMap[slot.ID] = true
	}
	return validMap
}
