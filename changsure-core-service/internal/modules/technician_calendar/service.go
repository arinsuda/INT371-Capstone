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
	storage      storage.Storage
	logger       *slog.Logger
}

func NewService(
	calendarRepo Repository,
	bookingRepo bookingPkg.Repository,
	timeSlotRepo timeslot.Repository,
	store storage.Storage,
	logger *slog.Logger,
) Service {
	if logger == nil {
		logger = slog.Default()
	}
	return &service{
		calendarRepo: calendarRepo,
		bookingRepo:  bookingRepo,
		timeSlotRepo: timeSlotRepo,
		storage:      store,
		logger:       logger,
	}
}

func (s *service) GetMonthlyCalendar(ctx context.Context, q CalendarQuery) (*CalendarResponse, error) {
	monthStart, err := q.ParseMonth()
	if err != nil {
		return nil, fmt.Errorf("invalid month: %w", err)
	}

	dateRange := CalculateMonthRange(monthStart)

	s.logger.Debug("fetching monthly calendar",
		slog.Uint64("technician_id", uint64(q.TechnicianID)),
		slog.String("month", q.Month),
		slog.String("range_start", booking.FormatDate(dateRange.Start)),
		slog.String("range_end", booking.FormatDate(dateRange.End)),
	)

	data, err := s.fetchCalendarData(ctx, q.TechnicianID, dateRange)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch calendar data: %w", err)
	}

	days := s.generateCalendarDays(ctx, dateRange, data)

	s.logger.Info("monthly calendar generated",
		slog.Uint64("technician_id", uint64(q.TechnicianID)),
		slog.String("month", q.Month),
		slog.Int("days_count", len(days)),
		slog.Int("closed_dates", len(data.ClosedDates)),
	)

	return &CalendarResponse{
		Month: q.Month,
		Days:  days,
	}, nil
}

func (s *service) GetCalendarDayBookings(ctx context.Context, q CalendarDayQuery, date time.Time) ([]BookingDetail, error) {
	dateStr := booking.FormatDate(date)

	s.logger.Debug("fetching calendar day bookings",
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

	filtered := bookings
	if q.TimeSlotID != nil {
		filtered = make([]bookingPkg.Booking, 0, len(bookings))
		for _, b := range bookings {
			if b.TimeSlotID == *q.TimeSlotID {
				filtered = append(filtered, b)
			}
		}
		s.logger.Debug("filtered bookings by timeslot",
			slog.Uint64("technician_id", uint64(q.TechnicianID)),
			slog.String("date", dateStr),
			slog.Uint64("timeslot_id", uint64(*q.TimeSlotID)),
			slog.Int("before", len(bookings)),
			slog.Int("after", len(filtered)),
		)
	}

	details := s.convertBookingsToDetails(ctx, filtered)

	s.logger.Info("calendar day bookings fetched",
		slog.Uint64("technician_id", uint64(q.TechnicianID)),
		slog.String("date", dateStr),
		slog.Int("count", len(details)),
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

	s.logger.Debug("updating calendar date",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", req.Date),
		slog.Bool("is_open", req.IsOpen),
		slog.Bool("is_closed", isClosed),
	)

	if err := s.calendarRepo.SetClosedDate(ctx, technicianID, date, isClosed); err != nil {
		s.logger.Error("failed to update calendar date",
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.String("date", req.Date),
			slog.String("error", err.Error()),
		)
		return nil, fmt.Errorf("database error: %w", err)
	}

	s.logger.Info("calendar date updated",
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
	if len(req.TimeSlotIDs) > 0 {
		if err := s.validateTimeSlotIDs(ctx, req.TimeSlotIDs); err != nil {
			s.logger.Warn("invalid time slot ids",
				slog.Uint64("technician_id", uint64(technicianID)),
				slog.Any("slot_ids", req.TimeSlotIDs),
				slog.String("error", err.Error()),
			)
			return nil, err
		}
	}

	if !req.IsDefault && booking.IsPastDate(date) {
		s.logger.Warn("attempted to update time slots for past date",
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.String("date", booking.FormatDate(date)),
		)
		return nil, ErrPastDate
	}

	s.logger.Debug("updating time slots",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.Bool("is_default", req.IsDefault),
		slog.String("date", booking.FormatDate(date)),
		slog.Int("slot_count", len(req.TimeSlotIDs)),
	)

	if err := s.updateTimeSlots(ctx, technicianID, date, req); err != nil {
		s.logger.Error("failed to update time slots",
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.String("error", err.Error()),
		)
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

	s.logger.Info("time slots updated",
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

func (s *service) fetchCalendarData(ctx context.Context, technicianID uint, dr DateRange) (*CalendarData, error) {
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

	s.logger.Debug("calendar data fetched",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.Int("closed_dates", len(closedDates)),
		slog.Int("time_slot_configs", len(timeSlots)),
		slog.Int("system_slots", len(allTimeSlots)),
		slog.Int("bookings", len(bookings)),
	)

	return &CalendarData{
		ClosedDates:  closedDates,
		TimeSlots:    timeSlots,
		AllTimeSlots: allTimeSlots,
		Bookings:     BuildBookingMap(bookingInfos),
		AllBookings:  s.groupBookingsByDate(bookings),
	}, nil
}

func (s *service) generateCalendarDays(ctx context.Context, dr DateRange, data *CalendarData) []CalendarDayStatus {
	days := make([]CalendarDayStatus, 0, 31)

	for cur := dr.Start; !cur.After(dr.End); cur = cur.AddDate(0, 0, 1) {
		dateStr := booking.FormatDate(cur)

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

		total := CountActiveSlots(slotDetails)
		booked := CountBookedActiveSlots(slotDetails)

		days = append(days, CalendarDayStatus{
			Date:           dateStr,
			Status:         CalculateDayStatus(total, booked),
			TotalSlots:     total,
			BookedSlots:    booked,
			AvailableSlots: total - booked,
			TimeSlots:      slotDetails,
			Bookings:       s.convertBookingsToDetails(ctx, data.AllBookings[dateStr]),
		})
	}

	return days
}

func (s *service) fetchBookingsForRange(ctx context.Context, technicianID uint, dr DateRange) ([]bookingPkg.Booking, error) {
	const limit = 500
	var (
		all    []bookingPkg.Booking
		offset = 0
	)
	startStr := booking.FormatDate(dr.Start)
	endStr := booking.FormatDate(dr.End)

	for {
		list, total, err := s.bookingRepo.ListByTechnician(ctx, technicianID, nil, startStr, endStr, offset, limit)
		if err != nil {
			return nil, fmt.Errorf("repository error: %w", err)
		}
		if len(list) == 0 {
			break
		}
		all = append(all, list...)
		offset += limit
		if offset >= int(total) {
			break
		}
	}

	s.logger.Debug("bookings fetched for range",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("start", startStr),
		slog.String("end", endStr),
		slog.Int("total", len(all)),
	)

	return all, nil
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

func (s *service) groupBookingsByDate(bookings []bookingPkg.Booking) map[string][]bookingPkg.Booking {
	result := make(map[string][]bookingPkg.Booking)
	for _, b := range bookings {
		if !IsActiveStatus(b.Status) {
			continue
		}
		dateKey := booking.FormatDate(b.AppointmentDate)
		result[dateKey] = append(result[dateKey], b)
	}
	return result
}

func (s *service) convertBookingsToDetails(ctx context.Context, bookings []bookingPkg.Booking) []BookingDetail {
	if len(bookings) == 0 {
		return []BookingDetail{}
	}

	details := make([]BookingDetail, 0, len(bookings))
	const ttl = 6 * time.Hour

	for _, b := range bookings {

		serviceImages := make([]string, 0, len(b.TechnicianService.Service.ImageURLs))
		for _, key := range b.TechnicianService.Service.ImageURLs {
			if key == "" {
				continue
			}
			url, err := s.storage.PresignGet(ctx, key, ttl, false)
			if err != nil {
				s.logger.Warn("presign service image failed",
					slog.String("key", key),
					slog.String("error", err.Error()),
				)
				continue
			}
			serviceImages = append(serviceImages, url)
		}

		var avatarURL string
		if b.Customer.AvatarURL != nil && *b.Customer.AvatarURL != "" {
			url, err := s.storage.PresignGet(ctx, *b.Customer.AvatarURL, ttl, false)
			if err != nil {
				s.logger.Warn("presign customer avatar failed",
					slog.String("key", *b.Customer.AvatarURL),
					slog.String("error", err.Error()),
				)
			} else {
				avatarURL = url
			}
		}

		imageURLs := make([]string, 0, len(b.Images))
		for _, img := range b.Images {
			if img.ImageURL == "" {
				continue
			}
			url, err := s.storage.PresignGet(ctx, img.ImageURL, ttl, false)
			if err != nil {
				s.logger.Warn("presign booking image failed",
					slog.String("key", img.ImageURL),
					slog.String("error", err.Error()),
				)
				continue
			}
			imageURLs = append(imageURLs, url)
		}

		serviceName := ""
		if b.TechnicianService.Service.ID > 0 {
			serviceName = b.TechnicianService.Service.SerName
		}

		details = append(details, BookingDetail{
			ID:              b.ID,
			BookingNumber:   b.BookingNumber,
			TimeSlotID:      b.TimeSlotID,
			ServiceName:     serviceName,
			ServiceImages:   serviceImages,
			PricingType:     b.PricingType,
			QuotedPrice:     b.QuotedPriceFixed,
			QuotedPriceMin:  b.QuotedPriceMin,
			QuotedPriceMax:  b.QuotedPriceMax,
			FinalPrice:      b.FinalPrice,
			AppointmentDate: booking.FormatDate(b.AppointmentDate),
			Status:          b.Status,
			CustomerID:      b.CustomerID,
			CustomerName:    fmt.Sprintf("%s %s", b.Customer.FirstName, b.Customer.LastName),
			CustomerPhone:   safeString(b.Customer.Phone),
			CustomerAvatar:  avatarURL,
			Images:          imageURLs,
		})
	}

	return details
}

func (s *service) updateTimeSlots(ctx context.Context, technicianID uint, date time.Time, req UpdateTimeSlotsRequest) error {
	s.logger.Debug("setting date-specific time slots",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", booking.FormatDate(date)),
		slog.Int("slot_count", len(req.TimeSlotIDs)),
	)
	if err := s.calendarRepo.SetDateTimeSlots(ctx, technicianID, date, req.TimeSlotIDs); err != nil {
		return err
	}

	if req.IsDefault {
		s.logger.Debug("setting default time slots",
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.Int("slot_count", len(req.TimeSlotIDs)),
		)
		return s.calendarRepo.SetDefaultTimeSlots(ctx, technicianID, req.TimeSlotIDs)
	}

	return nil
}

func (s *service) validateTimeSlotIDs(ctx context.Context, slotIDs []uint) error {
	allSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return fmt.Errorf("failed to fetch time slots: %w", err)
	}
	return ValidateSlotIDs(slotIDs, BuildValidSlotMap(allSlots))
}

func (s *service) buildFullSlotResponse(ctx context.Context, activeIDs []uint) ([]CalendarTimeSlot, error) {
	allSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch active slots: %w", err)
	}

	activeMap := make(map[uint]bool, len(activeIDs))
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
