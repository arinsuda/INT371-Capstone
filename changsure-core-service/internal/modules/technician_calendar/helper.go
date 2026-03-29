package techniciancalendar

import (
	"time"

	"changsure-core-service/internal/modules/booking"
	bookingPkg "changsure-core-service/internal/modules/booking"
	timeslot "changsure-core-service/internal/modules/time_slot"
)

type DateRange struct {
	Start time.Time
	End   time.Time
}

func CalculateMonthRange(monthStart time.Time) DateRange {
	year, month, _ := monthStart.Date()
	first := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	last := first.AddDate(0, 1, -1)
	return DateRange{Start: first, End: last}
}

type BookingInfo struct {
	Date       time.Time
	TimeSlotID uint
	Status     string
}

type CalendarData struct {
	ClosedDates  map[string]bool
	TimeSlots    map[string][]uint
	AllTimeSlots []timeslot.TimeSlot
	Bookings     map[string]map[uint]bool
	AllBookings  map[string][]bookingPkg.Booking
}

func BuildBookingMap(bookings []BookingInfo) map[string]map[uint]bool {
	result := make(map[string]map[uint]bool)
	for _, b := range bookings {
		dateKey := b.Date.Format("2006-01-02")
		if result[dateKey] == nil {
			result[dateKey] = make(map[uint]bool)
		}
		result[dateKey][b.TimeSlotID] = true
	}
	return result
}

func BuildTimeSlotMap(slots []timeslot.TimeSlot) map[uint]timeslot.TimeSlot {
	m := make(map[uint]timeslot.TimeSlot, len(slots))
	for _, s := range slots {
		m[s.ID] = s
	}
	return m
}

func BuildValidSlotMap(slots []timeslot.TimeSlot) map[uint]bool {
	m := make(map[uint]bool, len(slots))
	for _, s := range slots {
		m[s.ID] = true
	}
	return m
}

func ValidateSlotIDs(slotIDs []uint, validSlots map[uint]bool) error {
	for _, id := range slotIDs {
		if !validSlots[id] {
			return ErrTimeSlotNotFound
		}
	}
	return nil
}

func buildSelectedMap(dateStr string, data *CalendarData) map[uint]bool {
	selected := make(map[uint]bool)

	if ids, ok := data.TimeSlots[dateStr]; ok {
		for _, id := range ids {
			selected[id] = true
		}
		return selected
	}

	if ids, ok := data.TimeSlots["__default__"]; ok {
		for _, id := range ids {
			selected[id] = true
		}
		return selected
	}

	for _, slot := range data.AllTimeSlots {
		selected[slot.ID] = true
	}
	return selected
}

func CalculateDayStatus(totalSlots, bookedSlots int) DayStatus {
	if totalSlots == 0 {
		return DayStatusClosed
	}
	if bookedSlots >= totalSlots {
		return DayStatusFull
	}
	return DayStatusAvailable
}

func IsDateClosed(date string, closed map[string]bool) bool {
	return closed[date]
}

func CreateClosedDay(dateStr string) CalendarDayStatus {
	return CalendarDayStatus{
		Date:           dateStr,
		Status:         DayStatusClosed,
		TotalSlots:     0,
		BookedSlots:    0,
		AvailableSlots: 0,
		TimeSlots:      []CalendarTimeSlot{},
		Bookings:       []BookingDetail{},
	}
}

func CountActiveSlots(slots []CalendarTimeSlot) int {
	count := 0
	for _, s := range slots {
		if s.IsActive {
			count++
		}
	}
	return count
}

func CountBookedActiveSlots(slots []CalendarTimeSlot) int {
	count := 0
	for _, s := range slots {
		if s.IsActive && s.IsBooked {
			count++
		}
	}
	return count
}

func IsActiveStatus(status string) bool {
	for _, s := range booking.ExcludedFromAvailability {
		if s == status {
			return false
		}
	}
	return true
}

func safeString(ptr *string) string {
	if ptr == nil {
		return ""
	}
	return *ptr
}
