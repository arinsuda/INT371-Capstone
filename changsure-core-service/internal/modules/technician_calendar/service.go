package techniciancalendar

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"changsure-core-service/internal/modules/booking"
	timeslot "changsure-core-service/internal/modules/time_slot"
)

// ===========================
// Errors
// ===========================

var (
	ErrTechnicianNotFound = errors.New("technician not found")
	ErrInvalidDateRange   = errors.New("invalid date range")
	ErrInvalidMonth       = errors.New("invalid month format")
	ErrPastDate           = errors.New("cannot update calendar for past dates")
	ErrTimeSlotNotFound   = errors.New("time slot not found")
)

// ===========================
// Service Interface
// ===========================

type Service interface {
	GetMonthlyCalendar(ctx context.Context, q CalendarQuery) (*CalendarResponse, error)
	UpdateCalendarDate(ctx context.Context, technicianID uint, req UpdateCalendarDateRequest) (*UpdateCalendarDateResponse, error)
	UpdateTimeSlotsForDate(ctx context.Context, technicianID uint, date time.Time, req UpdateTimeSlotsRequest) (*UpdateTimeSlotsResponse, error)
}

// ===========================
// Service Implementation
// ===========================

type service struct {
	calendarRepo Repository
	bookingRepo  booking.Repository
	timeSlotRepo timeslot.Repository
	logger       *slog.Logger
}

func NewService(
	calendarRepo Repository,
	bookingRepo booking.Repository,
	timeSlotRepo timeslot.Repository,
	logger *slog.Logger,
) Service {
	if logger == nil {
		logger = slog.Default()
	}

	return &service{
		calendarRepo: calendarRepo,
		bookingRepo:  bookingRepo,
		timeSlotRepo: timeSlotRepo,
		logger:       logger,
	}
}

// ===========================
// Public Methods
// ===========================

func (s *service) GetMonthlyCalendar(ctx context.Context, q CalendarQuery) (*CalendarResponse, error) {
	// 1. Parse และคำนวณ date range
	monthStart, err := q.ParseMonth()
	if err != nil {
		return nil, fmt.Errorf("invalid month: %w", err)
	}

	dateRange := CalculateMonthRange(monthStart)

	s.logger.Debug("getting monthly calendar",
		slog.Uint64("technician_id", uint64(q.TechnicianID)),
		slog.String("month", q.Month),
		slog.String("start", dateRange.Start.Format("2006-01-02")),
		slog.String("end", dateRange.End.Format("2006-01-02")),
	)

	// 2. Fetch data ทั้งหมด
	data, err := s.fetchCalendarData(ctx, q.TechnicianID, dateRange)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch calendar data: %w", err)
	}

	// 3. Generate calendar days
	days := s.generateCalendarDays(dateRange, data)

	s.logger.Info("calendar generated successfully",
		slog.Uint64("technician_id", uint64(q.TechnicianID)),
		slog.String("month", q.Month),
		slog.Int("days_count", len(days)),
	)

	return &CalendarResponse{
		Month: q.Month,
		Days:  days,
	}, nil
}

func (s *service) UpdateCalendarDate(ctx context.Context, technicianID uint, req UpdateCalendarDateRequest) (*UpdateCalendarDateResponse, error) {
	// 1. Parse date
	date, err := req.ParseDate()
	if err != nil {
		return nil, fmt.Errorf("invalid date format: %w", err)
	}

	// 2. Validate not past date
	if isPastDate(date) {
		s.logger.Warn("attempted to update past date",
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.String("date", req.Date),
		)
		return nil, ErrPastDate
	}

	// 3. Update in database
	if err := s.calendarRepo.UpsertCalendarDate(ctx, technicianID, date, req.IsOpen); err != nil {
		s.logger.Error("failed to update calendar date",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.String("date", req.Date),
		)
		return nil, fmt.Errorf("database error: %w", err)
	}

	// 4. Verify saved data (for debugging)
	if err := s.verifyCalendarDateSaved(ctx, technicianID, date, req.IsOpen); err != nil {
		s.logger.Warn("verification warning", slog.String("error", err.Error()))
	}

	s.logger.Info("calendar date updated successfully",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", req.Date),
		slog.Bool("is_open", req.IsOpen),
	)

	return &UpdateCalendarDateResponse{
		Date:   req.Date,
		IsOpen: req.IsOpen,
	}, nil
}

func (s *service) UpdateTimeSlotsForDate(ctx context.Context, technicianID uint, date time.Time, req UpdateTimeSlotsRequest) (*UpdateTimeSlotsResponse, error) {
	// 1. Validate not past date
	if !req.IsDefault && isPastDate(date) {
		return nil, ErrPastDate
	}

	// 2. Validate time slot IDs
	if len(req.TimeSlotIDs) > 0 {
		if err := s.validateTimeSlotIDs(ctx, req.TimeSlotIDs); err != nil {
			return nil, err
		}
	}

	// 3. Update time slots
	if err := s.updateTimeSlots(ctx, technicianID, date, req); err != nil {
		return nil, err
	}

	// 4. Fetch updated slot details
	timeSlotDetails, err := s.fetchTimeSlotDetails(ctx, req.TimeSlotIDs)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch slot details: %w", err)
	}

	s.logger.Info("time slots updated successfully",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", date.Format("2006-01-02")),
		slog.Bool("is_default", req.IsDefault),
		slog.Int("slot_count", len(timeSlotDetails)),
	)

	return &UpdateTimeSlotsResponse{
		Date:      date.Format("2006-01-02"),
		IsDefault: req.IsDefault,
		TimeSlots: timeSlotDetails,
	}, nil
}

// ===========================
// Private Helper Methods
// ===========================

func (s *service) fetchCalendarData(ctx context.Context, technicianID uint, dr DateRange) (*CalendarData, error) {
	// Fetch calendar dates (open/closed status)
	calendarDates, err := s.calendarRepo.GetCalendarDatesByRange(ctx, technicianID, dr.Start, dr.End)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch calendar dates: %w", err)
	}

	// Fetch time slot configurations
	timeSlots, err := s.calendarRepo.GetTimeSlotsForMonth(ctx, technicianID, dr.Start, dr.End)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch time slots: %w", err)
	}

	// Fetch all active system time slots
	allTimeSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch system time slots: %w", err)
	}

	// Fetch bookings
	bookings, err := s.fetchBookingsForRange(ctx, technicianID, dr)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch bookings: %w", err)
	}

	// Convert bookings to internal format
	bookingInfos := s.convertToBookingInfos(bookings)
	bookingMap := BuildBookingMap(bookingInfos)

	s.logger.Debug("calendar data fetched",
		slog.Int("calendar_dates", len(calendarDates)),
		slog.Int("time_slot_configs", len(timeSlots)),
		slog.Int("system_slots", len(allTimeSlots)),
		slog.Int("bookings", len(bookings)),
	)

	return &CalendarData{
		CalendarDates: calendarDates,
		TimeSlots:     timeSlots,
		AllTimeSlots:  allTimeSlots,
		Bookings:      bookingMap,
	}, nil
}

func (s *service) generateCalendarDays(dr DateRange, data *CalendarData) []CalendarDayStatus {
	days := make([]CalendarDayStatus, 0, 31)
	slotMap := BuildTimeSlotMap(data.AllTimeSlots)

	for currentDate := dr.Start; !currentDate.After(dr.End); currentDate = currentDate.AddDate(0, 0, 1) {
		dateStr := currentDate.Format("2006-01-02")

		// Check if date is closed
		if IsDateClosed(dateStr, data.CalendarDates) {
			days = append(days, CreateClosedDay(dateStr))
			continue
		}

		// Resolve which slots to use for this date
		slotIDs := ResolveSlotIDs(dateStr, data)

		// Build slot details with booking status
		bookedSlots := data.Bookings[dateStr]
		if bookedSlots == nil {
			bookedSlots = make(map[uint]bool)
		}

		slotDetails := BuildSlotDetails(slotIDs, slotMap, bookedSlots)

		// Calculate day status
		totalSlots := len(slotDetails)
		bookedCount := CountBookedSlots(slotDetails)
		availableSlots := totalSlots - bookedCount
		status := CalculateDayStatus(totalSlots, bookedCount)

		days = append(days, CalendarDayStatus{
			Date:           dateStr,
			Status:         status,
			TotalSlots:     totalSlots,
			BookedSlots:    bookedCount,
			AvailableSlots: availableSlots,
			TimeSlots:      slotDetails,
		})
	}

	return days
}

func (s *service) fetchBookingsForRange(ctx context.Context, technicianID uint, dr DateRange) ([]booking.Booking, error) {
	const maxBookings = 10000
	startStr := dr.Start.Format("2006-01-02")
	endStr := dr.End.Format("2006-01-02")

	bookings, _, err := s.bookingRepo.ListByTechnician(
		ctx,
		technicianID,
		nil,
		startStr,
		endStr,
		0,
		maxBookings,
	)

	if err != nil {
		return nil, fmt.Errorf("repository error: %w", err)
	}

	return bookings, nil
}

func (s *service) convertToBookingInfos(bookings []booking.Booking) []BookingInfo {
	infos := make([]BookingInfo, len(bookings))
	for i, b := range bookings {
		infos[i] = BookingInfo{
			Date:       b.AppointmentDate,
			TimeSlotID: b.TimeSlotID,
		}
	}
	return infos
}

func (s *service) validateTimeSlotIDs(ctx context.Context, slotIDs []uint) error {
	allSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return fmt.Errorf("failed to fetch time slots: %w", err)
	}

	validSlots := BuildValidSlotMap(allSlots)
	return ValidateSlotIDs(slotIDs, validSlots)
}

func (s *service) updateTimeSlots(ctx context.Context, technicianID uint, date time.Time, req UpdateTimeSlotsRequest) error {
	if req.IsDefault {
		s.logger.Debug("setting default time slots",
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.Int("slot_count", len(req.TimeSlotIDs)),
		)
		return s.calendarRepo.SetDefaultTimeSlots(ctx, technicianID, req.TimeSlotIDs)
	}

	s.logger.Debug("setting date-specific time slots",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", date.Format("2006-01-02")),
		slog.Int("slot_count", len(req.TimeSlotIDs)),
	)

	if len(req.TimeSlotIDs) == 0 {
		// Empty array = remove date-specific config
		return s.calendarRepo.DeleteDateTimeSlots(ctx, technicianID, date)
	}

	return s.calendarRepo.SetDateTimeSlots(ctx, technicianID, date, req.TimeSlotIDs)
}

func (s *service) fetchTimeSlotDetails(ctx context.Context, slotIDs []uint) ([]TimeSlotDetail, error) {
	if len(slotIDs) == 0 {
		return []TimeSlotDetail{}, nil
	}

	allSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return nil, err
	}

	slotMap := BuildTimeSlotMap(allSlots)
	details := make([]TimeSlotDetail, 0, len(slotIDs))

	for _, slotID := range slotIDs {
		slot, ok := slotMap[slotID]
		if !ok {
			continue
		}

		details = append(details, TimeSlotDetail{
			ID:        slot.ID,
			TimeRange: FormatTimeRange(slot.StartTime, slot.EndTime),
			IsBooked:  false,
		})
	}

	return details, nil
}

func (s *service) verifyCalendarDateSaved(ctx context.Context, technicianID uint, date time.Time, expectedIsOpen bool) error {
	saved, err := s.calendarRepo.GetCalendarDatesByRange(ctx, technicianID, date, date)
	if err != nil {
		return fmt.Errorf("failed to verify: %w", err)
	}

	dateStr := date.Format("2006-01-02")
	savedIsOpen, exists := saved[dateStr]

	if !exists {
		return fmt.Errorf("calendar date not found after save")
	}

	if savedIsOpen != expectedIsOpen {
		return fmt.Errorf("saved value mismatch: expected %v, got %v", expectedIsOpen, savedIsOpen)
	}

	s.logger.Debug("calendar date verification passed",
		slog.String("date", dateStr),
		slog.Bool("is_open", savedIsOpen),
	)

	return nil
}
