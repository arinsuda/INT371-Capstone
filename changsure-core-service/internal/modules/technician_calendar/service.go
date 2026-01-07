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
	scheduleRepo technicianschedule.Repository // ✅ Inject Schedule Repo
}

// ✅ อัปเดต Constructor
func NewService(bRepo booking.Repository, tRepo timeslot.Repository, sRepo technicianschedule.Repository) Service {
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

	// 1. ดึง Time Slots
	techSlots, err := s.timeSlotRepo.GetSlotsForTechnician(ctx, q.TechnicianID)
	if err != nil {
		return nil, err
	}

	// 2. ดึง Bookings
	bookings, err := s.bookingRepo.GetBookingsByRange(
		ctx,
		q.TechnicianID,
		firstOfMonth.Format("2006-01-02"),
		lastOfMonth.Format("2006-01-02"),
	)
	if err != nil {
		return nil, err
	}

	// 3. ✅ ดึง Weekly Schedule
	workingDays, err := s.scheduleRepo.GetWeeklySchedule(ctx, q.TechnicianID)
	if err != nil {
		return nil, err
	}
	// แปลงเป็น Map เพื่อให้เช็คง่าย
	isWorkingDayMap := make(map[int]bool)
	if len(workingDays) > 0 {
		for _, day := range workingDays {
			isWorkingDayMap[day] = true
		}
	} else {
		// ถ้าไม่ตั้งค่า ถือว่าทำทุกวัน หรือ หยุดทุกวัน (เลือกตาม Business Logic)
		// กรณีนี้สมมติ: ถ้าไม่ตั้งค่า = ทำงานทุกวัน (เพื่อไม่ให้ Calendar ว่างเปล่าตอนเริ่มใช้งาน)
		for i := 0; i <= 6; i++ {
			isWorkingDayMap[i] = true
		}
	}

	// 4. ✅ ดึงวันลา (Leaves)
	leavesMap, err := s.scheduleRepo.GetLeavesByRange(
		ctx,
		q.TechnicianID,
		firstOfMonth.Format("2006-01-02"),
		lastOfMonth.Format("2006-01-02"),
	)
	if err != nil {
		return nil, err
	}

	// Map Booking
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
		weekday := int(d.Weekday()) // 0=Sun, 1=Mon

		bookedInDay := bookedMap[dateStr]
		bookedCount := len(bookedInDay)

		// สร้าง Detail
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

		// ✅ คำนวณ Status โดยรวม Schedule และ Leaves
		status := "AVAILABLE"

		// 1. เช็ควันหยุด (Weekly)
		if !isWorkingDayMap[weekday] {
			status = "CLOSED"
		}
		// 2. เช็ควันลา (Leaves)
		if leavesMap[dateStr] {
			status = "CLOSED"
		}
		// 3. เช็ค TimeSlot
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
