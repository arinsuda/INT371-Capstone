package techniciancalendar

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"changsure-core-service/internal/modules/booking"
	bookingPkg "changsure-core-service/internal/modules/booking"
	timeslot "changsure-core-service/internal/modules/time_slot"
)

var (
	ErrTechnicianNotFound = errors.New("technician not found")
	ErrInvalidDateRange   = errors.New("invalid date range")
	ErrInvalidMonth       = errors.New("invalid month format")
	ErrPastDate           = errors.New("cannot update calendar for past dates")
	ErrTimeSlotNotFound   = errors.New("time slot not found")
)

type Service interface {
	GetMonthlyCalendar(ctx context.Context, q CalendarQuery) (*CalendarResponse, error)
	GetCalendarDayBookings(ctx context.Context, q CalendarDayQuery, date time.Time) ([]BookingDetail, error)
	UpdateCalendarDate(ctx context.Context, technicianID uint, req UpdateCalendarDateRequest) (*UpdateCalendarDateResponse, error)
	UpdateTimeSlotsForDate(ctx context.Context, technicianID uint, date time.Time, req UpdateTimeSlotsRequest) (*UpdateTimeSlotsResponse, error)
}

type service struct {
	calendarRepo Repository
	bookingRepo  bookingPkg.Repository
	timeSlotRepo timeslot.Repository
	logger       *slog.Logger
}

func NewService(
	calendarRepo Repository,
	bookingRepo bookingPkg.Repository,
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

func (s *service) GetMonthlyCalendar(ctx context.Context, q CalendarQuery) (*CalendarResponse, error) {

	monthStart, err := q.ParseMonth()
	if err != nil {
		return nil, fmt.Errorf("invalid month: %w", err)
	}

	dateRange := CalculateMonthRange(monthStart)

	s.logger.Debug("getting monthly calendar",
		slog.Uint64("technician_id", uint64(q.TechnicianID)),
		slog.String("month", q.Month),
		slog.String("start", booking.FormatDate(dateRange.Start)),
		slog.String("end", booking.FormatDate(dateRange.End)),
	)

	data, err := s.fetchCalendarData(ctx, q.TechnicianID, dateRange, q)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch calendar data: %w", err)
	}

	days := s.generateCalendarDays(ctx, dateRange, data)

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

func (s *service) GetCalendarDayBookings(ctx context.Context, q CalendarDayQuery, date time.Time) ([]BookingDetail, error) {
	dateStr := booking.FormatDate(date)

	s.logger.Debug("getting calendar day bookings",
		slog.Uint64("technician_id", uint64(q.TechnicianID)),
		slog.String("date", dateStr),
	)

	bookings, _, err := s.bookingRepo.ListByTechnician(
		ctx,
		q.TechnicianID,
		nil,
		dateStr,
		dateStr,
		0,
		100,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to fetch bookings: %w", err)
	}

	var filteredBookings []bookingPkg.Booking
	if q.TimeSlotID != nil {
		for _, b := range bookings {
			if b.TimeSlotID == *q.TimeSlotID {
				filteredBookings = append(filteredBookings, b)
			}
		}
	} else {
		filteredBookings = bookings
	}

	return s.convertBookingsToDetails(ctx, filteredBookings), nil
}

func (s *service) UpdateCalendarDate(ctx context.Context, technicianID uint, req UpdateCalendarDateRequest) (*UpdateCalendarDateResponse, error) {

	date, err := req.ParseDate()
	if err != nil {
		return nil, fmt.Errorf("invalid date format: %w", err)
	}

	if booking.IsPastDate(date) {
		s.logger.Warn("attempted to update past date",
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.String("date", req.Date),
		)
		return nil, ErrPastDate
	}

	isClosed := !req.IsOpen

	if err := s.calendarRepo.SetClosedDate(ctx, technicianID, date, isClosed); err != nil {
		s.logger.Error("failed to update calendar date",
			slog.String("error", err.Error()),
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.String("date", req.Date),
		)
		return nil, fmt.Errorf("database error: %w", err)
	}

	s.logger.Info("calendar date updated successfully",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", req.Date),
		slog.Bool("is_open", req.IsOpen),
		slog.Bool("is_closed", isClosed),
	)

	return &UpdateCalendarDateResponse{
		Date:   req.Date,
		IsOpen: req.IsOpen,
	}, nil
}

func (s *service) UpdateTimeSlotsForDate(ctx context.Context, technicianID uint, date time.Time, req UpdateTimeSlotsRequest) (*UpdateTimeSlotsResponse, error) {

	if len(req.TimeSlotIDs) > 0 {
		if err := s.validateTimeSlotIDs(ctx, req.TimeSlotIDs); err != nil {
			return nil, err
		}
	}

	if !req.IsDefault && booking.IsPastDate(date) {
		return nil, ErrPastDate
	}

	if err := s.updateTimeSlots(ctx, technicianID, date, req); err != nil {
		return nil, err
	}

	timeSlotDetails, err := s.buildFullSlotResponse(ctx, req.TimeSlotIDs)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch slot details: %w", err)
	}

	responseDate := "default"
	if !req.IsDefault {
		responseDate = booking.FormatDate(date)
	}

	s.logger.Info("time slots updated successfully",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", responseDate),
		slog.Bool("is_default", req.IsDefault),
		slog.Int("slot_count", len(timeSlotDetails)),
	)

	return &UpdateTimeSlotsResponse{
		Date:      responseDate,
		IsDefault: req.IsDefault,
		TimeSlots: timeSlotDetails,
	}, nil
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
		slog.String("date", booking.FormatDate(date)),
		slog.Int("slot_count", len(req.TimeSlotIDs)),
	)

	return s.calendarRepo.SetDateTimeSlots(ctx, technicianID, date, req.TimeSlotIDs)
}

func (s *service) fetchCalendarData(ctx context.Context, technicianID uint, dr DateRange, q CalendarQuery) (*CalendarData, error) {

	closedDates, err := s.calendarRepo.GetClosedDatesByRange(ctx, technicianID, dr.Start, dr.End)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch closed dates: %w", err)
	}

	timeSlots, err := s.calendarRepo.GetTimeSlotsForMonth(ctx, technicianID, dr.Start, dr.End)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch time slots: %w", err)
	}

	allTimeSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch system time slots: %w", err)
	}

	bookings, err := s.fetchBookingsForRange(ctx, technicianID, dr)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch bookings: %w", err)
	}

	bookingInfos := s.convertToBookingInfos(bookings)
	bookingMap := BuildBookingMap(bookingInfos)

	bookingsByDate := s.groupBookingsByDate(bookings)

	s.logger.Debug("calendar data fetched",
		slog.Int("closed_dates", len(closedDates)),
		slog.Int("time_slot_configs", len(timeSlots)),
		slog.Int("system_slots", len(allTimeSlots)),
		slog.Int("bookings", len(bookings)),
	)

	return &CalendarData{
		ClosedDates:  closedDates,
		TimeSlots:    timeSlots,
		AllTimeSlots: allTimeSlots,
		Bookings:     bookingMap,
		AllBookings:  bookingsByDate,
	}, nil
}

func (s *service) generateCalendarDays(ctx context.Context, dr DateRange, data *CalendarData) []CalendarDayStatus {
	days := make([]CalendarDayStatus, 0, 31)

	for currentDate := dr.Start; !currentDate.After(dr.End); currentDate = currentDate.AddDate(0, 0, 1) {
		dateStr := booking.FormatDate(currentDate)

		if IsDateClosed(dateStr, data.ClosedDates) {
			days = append(days, CreateClosedDay(dateStr))
			continue
		}

		selected := buildSelectedMap(dateStr, data)

		bookedSlots := data.Bookings[dateStr]
		if bookedSlots == nil {
			bookedSlots = make(map[uint]bool)
		}

		slotDetails := make([]CalendarTimeSlot, 0, len(data.AllTimeSlots))

		for _, slot := range data.AllTimeSlots {
			slotDetails = append(slotDetails, CalendarTimeSlot{
				ID:        slot.ID,
				StartTime: slot.StartTime,
				EndTime:   slot.EndTime,
				IsActive:  selected[slot.ID],
				CreatedAt: slot.CreatedAt,
				UpdatedAt: slot.UpdatedAt,
				IsBooked:  bookedSlots[slot.ID],
			})
		}

		totalSlots := CountActiveSlots(slotDetails)
		bookedCount := CountBookedActiveSlots(slotDetails)
		availableSlots := totalSlots - bookedCount
		status := CalculateDayStatus(totalSlots, bookedCount)

		bookingDetails := s.convertBookingsToDetails(ctx, data.AllBookings[dateStr])

		days = append(days, CalendarDayStatus{
			Date:           dateStr,
			Status:         status,
			TotalSlots:     totalSlots,
			BookedSlots:    bookedCount,
			AvailableSlots: availableSlots,
			TimeSlots:      slotDetails,
			Bookings:       bookingDetails,
		})
	}

	return days
}

func (s *service) resolveSlotIDsWithFallback(dateStr string, data *CalendarData) []uint {

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

func (s *service) fetchBookingsForRange(
	ctx context.Context,
	technicianID uint,
	dr DateRange,
) ([]bookingPkg.Booking, error) {

	const limit = 500

	startStr := booking.FormatDate(dr.Start)
	endStr := booking.FormatDate(dr.End)

	var (
		allBookings []bookingPkg.Booking
		offset      = 0
	)

	for {
		list, total, err := s.bookingRepo.ListByTechnician(
			ctx,
			technicianID,
			nil,
			startStr,
			endStr,
			offset,
			limit,
		)
		if err != nil {
			return nil, fmt.Errorf("repository error: %w", err)
		}

		if len(list) == 0 {
			break
		}

		allBookings = append(allBookings, list...)

		offset += limit

		if offset >= int(total) {
			break
		}
	}

	return allBookings, nil
}

func (s *service) convertToBookingInfos(bookings []bookingPkg.Booking) []BookingInfo {
	infos := make([]BookingInfo, 0, len(bookings))

	for _, b := range bookings {
		if !IsActiveStatus(b.Status) {
			continue
		}

		infos = append(infos, BookingInfo{
			Date:       b.AppointmentDate,
			TimeSlotID: b.TimeSlotID,
			Status:     b.Status,
		})
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

// func (s *service) fetchTimeSlotDetails(ctx context.Context, slotIDs []uint) ([]CalendarTimeSlot, error) {
// 	if len(slotIDs) == 0 {
// 		return []CalendarTimeSlot{}, nil
// 	}

// 	allSlots, err := s.timeSlotRepo.FindActive(ctx)
// 	if err != nil {
// 		return nil, err
// 	}

// 	slotMap := BuildTimeSlotMap(allSlots)
// 	details := make([]CalendarTimeSlot, 0, len(slotIDs))

// 	for _, slotID := range slotIDs {
// 		slot, ok := slotMap[slotID]
// 		if !ok {
// 			continue
// 		}

// 		details = append(details, CalendarTimeSlot{
// 			ID:        slot.ID,
// 			StartTime: slot.StartTime,
// 			EndTime:   slot.EndTime,
// 			IsActive:  slot.IsActive,
// 			CreatedAt: slot.CreatedAt,
// 			UpdatedAt: slot.UpdatedAt,
// 			IsBooked:  false,
// 		})
// 	}

// 	return details, nil
// }

func (s *service) buildFullSlotResponse(ctx context.Context, activeIDs []uint) ([]CalendarTimeSlot, error) {

	allSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return nil, err
	}

	activeMap := make(map[uint]bool)
	for _, id := range activeIDs {
		activeMap[id] = true
	}

	result := make([]CalendarTimeSlot, 0, len(allSlots))

	for _, slot := range allSlots {
		result = append(result, CalendarTimeSlot{
			ID:        slot.ID,
			StartTime: slot.StartTime,
			EndTime:   slot.EndTime,
			IsActive:  activeMap[slot.ID],
			CreatedAt: slot.CreatedAt,
			UpdatedAt: slot.UpdatedAt,
			IsBooked:  false,
		})
	}

	return result, nil
}
