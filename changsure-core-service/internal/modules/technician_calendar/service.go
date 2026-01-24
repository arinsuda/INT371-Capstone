package techniciancalendar

import (
	"context"
	"fmt"
	"time"

	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/modules/technician_schedule"
	timeslot "changsure-core-service/internal/modules/time_slot"
)

type Service interface {
	GetMonthlyCalendar(ctx context.Context, q CalendarQuery) (*CalendarResponse, error)
}

type service struct {
	bookingRepo  booking.Repository
	timeSlotRepo timeslot.Repository
	scheduleRepo technicianschedule.Repository
}

func NewService(
	bRepo booking.Repository,
	tRepo timeslot.Repository,
	sRepo technicianschedule.Repository,
) Service {
	return &service{
		bookingRepo:  bRepo,
		timeSlotRepo: tRepo,
		scheduleRepo: sRepo,
	}
}

func (s *service) GetMonthlyCalendar(ctx context.Context, q CalendarQuery) (*CalendarResponse, error) {
	startDate, err := time.Parse("2006-01", q.Month)
	if err != nil {
		return nil, fmt.Errorf("invalid month format (expected YYYY-MM)")
	}

	year, month, _ := startDate.Date()
	firstOfMonth := time.Date(year, month, 1, 0, 0, 0, 0, time.UTC)
	lastOfMonth := firstOfMonth.AddDate(0, 1, -1)

	techSlots, err := s.timeSlotRepo.GetSlotsForTechnician(ctx, q.TechnicianID)
	if err != nil {
		return nil, err
	}

	bookingDateStart := firstOfMonth.Format("2006-01-02")
	bookingDateEnd := lastOfMonth.Format("2006-01-02")

	var bookings []booking.Booking
	bookings, err = s.getBookingsByRange(ctx, q.TechnicianID, bookingDateStart, bookingDateEnd)
	if err != nil {
		return nil, err
	}

	workingDays, err := s.scheduleRepo.GetWeeklySchedule(ctx, q.TechnicianID)
	if err != nil {
		return nil, err
	}

	isWorkingDayMap := make(map[int]bool)
	if len(workingDays) > 0 {
		for _, day := range workingDays {
			isWorkingDayMap[day] = true
		}
	} else {

		for i := 0; i <= 6; i++ {
			isWorkingDayMap[i] = true
		}
	}

	leavesMap, err := s.scheduleRepo.GetLeavesByRange(
		ctx,
		q.TechnicianID,
		bookingDateStart,
		bookingDateEnd,
	)
	if err != nil {
		return nil, err
	}

	bookedMap := make(map[string]map[uint]bool)
	for _, b := range bookings {
		dateKey := b.AppointmentDate.Format("2006-01-02")
		if _, exists := bookedMap[dateKey]; !exists {
			bookedMap[dateKey] = make(map[uint]bool)
		}
		bookedMap[dateKey][b.TimeSlotID] = true
	}

	var days []CalendarDayStatus
	totalSlotsCount := len(techSlots)

	for d := firstOfMonth; !d.After(lastOfMonth); d = d.AddDate(0, 0, 1) {
		dateStr := d.Format("2006-01-02")
		weekday := int(d.Weekday())

		bookedInDay := bookedMap[dateStr]
		bookedCount := len(bookedInDay)

		slotDetails := make([]TimeSlotDetail, 0, totalSlotsCount)
		for _, slot := range techSlots {
			isBooked := false
			if bookedInDay != nil {
				isBooked = bookedInDay[slot.ID]
			}
			slotDetails = append(slotDetails, TimeSlotDetail{
				ID:        slot.ID,
				TimeRange: fmt.Sprintf("%s - %s", slot.StartTime, slot.EndTime),
				IsBooked:  isBooked,
			})
		}

		status := "AVAILABLE"

		if !isWorkingDayMap[weekday] {
			status = "CLOSED"
		}

		if leavesMap[dateStr] {
			status = "CLOSED"
		}

		if status != "CLOSED" {
			if totalSlotsCount == 0 {
				status = "CLOSED"
			} else if bookedCount >= totalSlotsCount {
				status = "FULL"
			}
		}

		days = append(days, CalendarDayStatus{
			Date:           dateStr,
			Status:         status,
			TotalSlots:     totalSlotsCount,
			BookedSlots:    bookedCount,
			AvailableSlots: totalSlotsCount - bookedCount,
			TimeSlots:      slotDetails,
		})
	}

	return &CalendarResponse{
		Month: q.Month,
		Days:  days,
	}, nil
}

func (s *service) getBookingsByRange(ctx context.Context, technicianID uint, start, end string) ([]booking.Booking, error) {

	bookings, _, err := s.bookingRepo.ListByTechnician(
		ctx,
		technicianID,
		nil,
		start,
		end,
		0,
		10000,
	)
	return bookings, err
}
