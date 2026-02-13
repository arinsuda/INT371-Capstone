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
	"changsure-core-service/pkg/storage"
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

	details := make([]BookingDetail, len(filteredBookings))
	for i, b := range filteredBookings {

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
				ctx,
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

	s.logger.Info("calendar day bookings retrieved",
		slog.Uint64("technician_id", uint64(q.TechnicianID)),
		slog.String("date", dateStr),
		slog.Int("booking_count", len(details)),
	)

	return details, nil
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
	// Validate time slot IDs exist
	if len(req.TimeSlotIDs) > 0 {
		if err := s.validateTimeSlotIDs(ctx, req.TimeSlotIDs); err != nil {
			return nil, err
		}
	}

	// Check for past date if not default
	if !req.IsDefault && booking.IsPastDate(date) {
		return nil, ErrPastDate
	}

	// Update time slots
	if err := s.updateTimeSlots(ctx, technicianID, date, req); err != nil {
		return nil, err
	}

	// Fetch time slot details
	timeSlotDetails, err := s.fetchTimeSlotDetails(ctx, req.TimeSlotIDs)
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
	// Get closed dates
	closedDates, err := s.calendarRepo.GetClosedDatesByRange(ctx, technicianID, dr.Start, dr.End)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch closed dates: %w", err)
	}

	// Get time slot configurations
	timeSlots, err := s.calendarRepo.GetTimeSlotsForMonth(ctx, technicianID, dr.Start, dr.End)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch time slots: %w", err)
	}

	// Get all active system time slots
	allTimeSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch system time slots: %w", err)
	}

	// Get bookings for the month
	bookings, err := s.fetchBookingsForRange(ctx, technicianID, dr)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch bookings: %w", err)
	}

	bookingInfos := s.convertToBookingInfos(bookings)
	bookingMap := BuildBookingMap(bookingInfos)

	// แก้: เพิ่ม AllBookings เก็บ bookings ทั้งหมด
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

func (s *service) generateCalendarDays(dr DateRange, data *CalendarData) []CalendarDayStatus {
	days := make([]CalendarDayStatus, 0, 31)
	slotMap := BuildTimeSlotMap(data.AllTimeSlots)

	for currentDate := dr.Start; !currentDate.After(dr.End); currentDate = currentDate.AddDate(0, 0, 1) {
		dateStr := booking.FormatDate(currentDate)

		// Check if date is closed
		if IsDateClosed(dateStr, data.ClosedDates) {
			days = append(days, CreateClosedDay(dateStr))
			continue
		}

		// Resolve which slots are active for this date (with system fallback)
		slotIDs := s.resolveSlotIDsWithFallback(dateStr, data)

		// Get booked slots
		bookedSlots := data.Bookings[dateStr]
		if bookedSlots == nil {
			bookedSlots = make(map[uint]bool)
		}

		// Build slot details
		slotDetails := BuildSlotDetails(slotIDs, slotMap, bookedSlots)

		totalSlots := len(slotDetails)
		bookedCount := CountBookedSlots(slotDetails)
		availableSlots := totalSlots - bookedCount
		status := CalculateDayStatus(totalSlots, bookedCount)

		// แก้: เพิ่ม bookings รายละเอียด
		bookingDetails := s.convertBookingsToDetails(data.AllBookings[dateStr])

		days = append(days, CalendarDayStatus{
			Date:           dateStr,
			Status:         status,
			TotalSlots:     totalSlots,
			BookedSlots:    bookedCount,
			AvailableSlots: availableSlots,
			TimeSlots:      slotDetails,
			Bookings:       bookingDetails, // เพิ่มบรรทัดนี้
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

func (s *service) fetchBookingsForRange(ctx context.Context, technicianID uint, dr DateRange) ([]bookingPkg.Booking, error) {
	const maxBookings = 10000
	startStr := booking.FormatDate(dr.Start)
	endStr := booking.FormatDate(dr.End)

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

func (s *service) convertToBookingInfos(bookings []bookingPkg.Booking) []BookingInfo {
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
