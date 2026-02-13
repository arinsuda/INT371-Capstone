package techniciancalendar

import (
	"context"
	"fmt"
	"log/slog"
	"time"

	"changsure-core-service/internal/modules/booking"
	bookingPkg "changsure-core-service/internal/modules/booking"
	timeslot "changsure-core-service/internal/modules/time_slot"
	"changsure-core-service/pkg/storage"
)

type DateRange struct {
	Start time.Time
	End   time.Time
}

type CalendarData struct {
	ClosedDates   map[string]bool
	CalendarDates map[string]bool
	TimeSlots     map[string][]uint
	AllTimeSlots  []timeslot.TimeSlot
	Bookings      map[string]map[uint]bool
	AllBookings   map[string][]bookingPkg.Booking
}

type BookingInfo struct {
	Date       time.Time
	TimeSlotID uint
}

func CalculateMonthRange(monthStart time.Time) DateRange {
	year, month, _ := monthStart.Date()
	firstOfMonth := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	lastOfMonth := firstOfMonth.AddDate(0, 1, -1)

	return DateRange{
		Start: firstOfMonth,
		End:   lastOfMonth,
	}
}

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

func BuildTimeSlotMap(slots []timeslot.TimeSlot) map[uint]timeslot.TimeSlot {
	slotMap := make(map[uint]timeslot.TimeSlot)
	for _, slot := range slots {
		slotMap[slot.ID] = slot
	}
	return slotMap
}

func ResolveSlotIDs(dateStr string, data *CalendarData) []uint {

	if specificSlots, ok := data.TimeSlots[dateStr]; ok && len(specificSlots) > 0 {
		return specificSlots
	}

	if defaultSlots, ok := data.TimeSlots["__default__"]; ok && len(defaultSlots) > 0 {
		return defaultSlots
	}

	systemSlotIDs := make([]uint, len(data.AllTimeSlots))
	for i, slot := range data.AllTimeSlots {
		systemSlotIDs[i] = slot.ID
	}
	return systemSlotIDs
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
	if len(closed) == 0 {
		return false
	}
	_, exists := closed[date]
	return exists
}

func CreateClosedDay(dateStr string) CalendarDayStatus {
	return CalendarDayStatus{
		Date:           dateStr,
		Status:         DayStatusClosed,
		TotalSlots:     0,
		BookedSlots:    0,
		AvailableSlots: 0,
		TimeSlots:      []TimeSlotDetail{},
		Bookings:       []BookingDetail{},
	}
}

func BuildSlotDetails(
	slotIDs []uint,
	slotMap map[uint]timeslot.TimeSlot,
	bookedSlots map[uint]bool,
) []TimeSlotDetail {
	details := make([]TimeSlotDetail, 0, len(slotIDs))

	for _, slotID := range slotIDs {
		slot, ok := slotMap[slotID]
		if !ok {

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

func FormatTimeRange(start, end string) string {
	return start + " - " + end
}

func CountBookedSlots(slots []TimeSlotDetail) int {
	count := 0
	for _, slot := range slots {
		if slot.IsBooked {
			count++
		}
	}
	return count
}

func ValidateSlotIDs(slotIDs []uint, validSlots map[uint]bool) error {
	for _, slotID := range slotIDs {
		if !validSlots[slotID] {
			return ErrTimeSlotNotFound
		}
	}
	return nil
}

func BuildValidSlotMap(slots []timeslot.TimeSlot) map[uint]bool {
	validMap := make(map[uint]bool)
	for _, slot := range slots {
		validMap[slot.ID] = true
	}
	return validMap
}

func (s *service) groupBookingsByDate(bookings []bookingPkg.Booking) map[string][]bookingPkg.Booking {
	result := make(map[string][]bookingPkg.Booking)

	for _, b := range bookings {
		dateKey := booking.FormatDate(b.AppointmentDate)
		result[dateKey] = append(result[dateKey], b)
	}

	return result
}

func (s *service) convertBookingsToDetails(bookings []bookingPkg.Booking) []BookingDetail {
	if len(bookings) == 0 {
		return []BookingDetail{}
	}

	details := make([]BookingDetail, len(bookings))

	for i, b := range bookings {
		customerName := fmt.Sprintf("%s %s", b.Customer.FirstName, b.Customer.LastName)

		serviceName := ""
		if b.TechnicianService.Service.ID > 0 {
			serviceName = b.TechnicianService.Service.SerName
		}

		imageURLs := make([]string, len(b.Images))

		for j, img := range b.Images {

			key := img.ImageURL

			if key == "" {
				continue
			}

			url, err := storage.GlobalMinio.PresignGet(
				context.Background(),
				key,
				time.Hour*6,
				false,
			)

			if err != nil {
				s.logger.Warn("presign image failed",
					slog.String("key", key),
					slog.String("error", err.Error()),
				)
				continue
			}

			imageURLs[j] = url
		}

		details[i] = BookingDetail{
			ID:              b.ID,
			BookingNumber:   b.BookingNumber,
			TimeSlotID:      b.TimeSlotID,
			ServiceName:     serviceName,
			PricingType:     b.PricingType,
			QuotedPrice:     b.QuotedPriceFixed,
			QuotedPriceMin:  b.QuotedPriceMin,
			QuotedPriceMax:  b.QuotedPriceMax,
			FinalPrice:      b.FinalPrice,
			AppointmentDate: booking.FormatDate(b.AppointmentDate),
			Status:          b.Status,
			CustomerID:      b.CustomerID,
			CustomerName:    customerName,
			CustomerPhone:   safeString(b.Customer.Phone),
			CustomerAvatar:  safeString(b.Customer.AvatarURL),
			Images:          imageURLs,
		}
	}

	return details
}

func safeString(ptr *string) string {
	if ptr == nil {
		return ""
	}
	return *ptr
}
