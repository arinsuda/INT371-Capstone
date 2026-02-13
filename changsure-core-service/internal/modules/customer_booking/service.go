package customerbooking

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/modules/notification"
	techniciancalendar "changsure-core-service/internal/modules/technician_calendar"
	timeslot "changsure-core-service/internal/modules/time_slot"
	"changsure-core-service/pkg/utils"

	"gorm.io/gorm"
)

var (
	ErrSlotBooked            = errors.New("ช่วงเวลานี้ถูกจองเต็มแล้ว")
	ErrServiceNotFound       = errors.New("ไม่พบบริการที่เลือก")
	ErrAddressNotFound       = errors.New("ที่อยู่ไม่ถูกต้องหรือไม่มีสิทธิ์ใช้งาน")
	ErrInvalidDateFormat     = errors.New("รูปแบบวันที่ไม่ถูกต้อง (ต้องเป็น YYYY-MM-DD)")
	ErrTechnicianClosed      = errors.New("ช่างปิดรับงานในวันที่เลือก")
	ErrInvalidTimeSlot       = errors.New("ช่วงเวลาไม่ถูกต้องหรือมีการเปลี่ยนแปลง กรุณาเลือกใหม่")
	ErrServiceAreaNotCovered = errors.New("ช่างไม่ให้บริการในพื้นที่นี้")

	ErrBookingNotFound             = errors.New("ไม่พบข้อมูลการจอง")
	ErrForbiddenBooking            = errors.New("คุณไม่มีสิทธิ์เข้าถึงรายการนี้")
	ErrBookingIsStartedOrCompleted = errors.New("ไม่สามารถยกเลิกรายการที่กำลังดำเนินการหรือเสร็จสิ้นแล้ว")
)

type Service interface {
	GetAvailableTimeSlots(ctx context.Context, technicianID uint, dateStr string) ([]TimeSlotAvailability, error)
	CreateBooking(ctx context.Context, customerID uint, req CreateBookingRequest) (*booking.Booking, error)
	GetBookingDetail(ctx context.Context, bookingID uint) (*booking.Booking, error)
	CancelBooking(ctx context.Context, customerID, bookingID uint, reason string) (*booking.Booking, error)
	ListBookings(ctx context.Context, customerID uint, q ListBookingsQuery) ([]booking.Booking, int64, int, int, error)
}

type service struct {
	repo         booking.Repository
	timeSlotRepo timeslot.Repository
	calendarRepo techniciancalendar.Repository
	db           *gorm.DB
	notif        notification.Service
	logger       *slog.Logger
}

func NewService(
	repo booking.Repository,
	timeSlotRepo timeslot.Repository,
	calendarRepo techniciancalendar.Repository,
	db *gorm.DB,
	notif notification.Service,
	logger *slog.Logger,
) Service {
	if logger == nil {
		logger = slog.Default()
	}
	return &service{
		repo:         repo,
		timeSlotRepo: timeSlotRepo,
		calendarRepo: calendarRepo,
		db:           db,
		notif:        notif,
		logger:       logger,
	}
}

func (s *service) GetAvailableTimeSlots(ctx context.Context, technicianID uint, dateStr string) ([]TimeSlotAvailability, error) {
	// Use centralized timezone parsing
	parsedDate, err := booking.ParseDate(dateStr)
	if err != nil {
		return nil, ErrInvalidDateFormat
	}

	s.logger.Debug("checking slot availability",
		slog.Uint64("technician_id", uint64(technicianID)),
		slog.String("date", dateStr),
	)

	// Check if technician is closed on this date
	closedDates, err := s.calendarRepo.GetClosedDatesByRange(ctx, technicianID, parsedDate, parsedDate)
	if err != nil {
		s.logger.Error("failed to get closed dates", slog.String("error", err.Error()))
		return nil, err
	}

	if closedDates[dateStr] {
		s.logger.Info("technician closed on date",
			slog.Uint64("technician_id", uint64(technicianID)),
			slog.String("date", dateStr),
		)
		return []TimeSlotAvailability{}, nil
	}

	// Get active slot IDs for this specific date
	activeSlotIDs, err := s.calendarRepo.GetTimeSlotsForDate(ctx, technicianID, &parsedDate)
	if err != nil {
		s.logger.Error("failed to get time slots for date", slog.String("error", err.Error()))
		return nil, err
	}

	// If no specific slots, get default slots
	if len(activeSlotIDs) == 0 {
		activeSlotIDs, err = s.calendarRepo.GetTimeSlotsForDate(ctx, technicianID, nil)
		if err != nil {
			s.logger.Error("failed to get default time slots", slog.String("error", err.Error()))
			return nil, err
		}
	}

	// If still no slots, get all active system slots as fallback
	if len(activeSlotIDs) == 0 {
		allSlots, err := s.timeSlotRepo.FindActive(ctx)
		if err != nil {
			s.logger.Error("failed to get system time slots", slog.String("error", err.Error()))
			return nil, err
		}
		for _, slot := range allSlots {
			activeSlotIDs = append(activeSlotIDs, slot.ID)
		}
		s.logger.Debug("using system default slots", slog.Int("count", len(activeSlotIDs)))
	}

	if len(activeSlotIDs) == 0 {
		return []TimeSlotAvailability{}, nil
	}

	// Get all active system time slots for details
	allActiveSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		s.logger.Error("failed to get active slots", slog.String("error", err.Error()))
		return nil, err
	}

	// Get already booked slots for this date
	bookedSlotIDs, err := s.repo.GetBookedSlotIDs(ctx, technicianID, dateStr)
	if err != nil {
		s.logger.Error("failed to get booked slots", slog.String("error", err.Error()))
		return nil, err
	}

	// Build lookup maps
	bookedMap := make(map[uint]bool)
	for _, id := range bookedSlotIDs {
		bookedMap[id] = true
	}

	activeMap := make(map[uint]bool)
	for _, id := range activeSlotIDs {
		activeMap[id] = true
	}

	// Build result with only active slots
	result := make([]TimeSlotAvailability, 0)
	for _, slot := range allActiveSlots {
		if activeMap[slot.ID] {
			result = append(result, TimeSlotAvailability{
				ID:          slot.ID,
				Label:       fmt.Sprintf("%s - %s", slot.StartTime, slot.EndTime),
				IsAvailable: !bookedMap[slot.ID],
			})
		}
	}

	s.logger.Info("slot availability checked",
		slog.Int("total_slots", len(result)),
		slog.Int("booked_slots", len(bookedSlotIDs)),
	)

	return result, nil
}

func (s *service) CreateBooking(ctx context.Context, customerID uint, req CreateBookingRequest) (*booking.Booking, error) {
	// Use centralized timezone parsing
	appointDate, err := booking.ParseDate(req.AppointmentDate)
	if err != nil {
		return nil, ErrInvalidDateFormat
	}

	// Check for past date
	if booking.IsPastDate(appointDate) {
		s.logger.Warn("attempted to book past date",
			slog.Uint64("customer_id", uint64(customerID)),
			slog.String("date", req.AppointmentDate),
		)
		return nil, errors.New("ไม่สามารถจองย้อนหลังได้")
	}

	dateStr := booking.FormatDate(appointDate) // Use centralized formatting

	s.logger.Info("creating booking",
		slog.Uint64("customer_id", uint64(customerID)),
		slog.Uint64("technician_id", uint64(req.TechnicianID)),
		slog.String("date", dateStr),
		slog.Uint64("slot_id", uint64(req.TimeSlotID)),
	)

	// Check if technician is closed on this date
	closedDates, err := s.calendarRepo.GetClosedDatesByRange(ctx, req.TechnicianID, appointDate, appointDate)
	if err != nil {
		s.logger.Error("failed to check closed dates", slog.String("error", err.Error()))
		return nil, err
	}

	if closedDates[dateStr] {
		s.logger.Warn("technician closed on booking date",
			slog.Uint64("technician_id", uint64(req.TechnicianID)),
			slog.String("date", dateStr),
		)
		return nil, ErrTechnicianClosed
	}

	// Validate time slot is allowed for this date
	allowedSlots, err := s.calendarRepo.GetTimeSlotsForDate(ctx, req.TechnicianID, &appointDate)
	if err != nil {
		s.logger.Error("failed to get allowed slots", slog.String("error", err.Error()))
		return nil, err
	}

	// If no specific slots, get default slots
	if len(allowedSlots) == 0 {
		allowedSlots, err = s.calendarRepo.GetTimeSlotsForDate(ctx, req.TechnicianID, nil)
		if err != nil {
			s.logger.Error("failed to get default slots", slog.String("error", err.Error()))
			return nil, err
		}
	}

	// If still no slots, allow all active system slots
	if len(allowedSlots) == 0 {
		allSlots, err := s.timeSlotRepo.FindActive(ctx)
		if err != nil {
			s.logger.Error("failed to get system slots", slog.String("error", err.Error()))
			return nil, err
		}
		for _, slot := range allSlots {
			allowedSlots = append(allowedSlots, slot.ID)
		}
	}

	// Check if requested slot is in allowed list
	isAllowed := false
	for _, id := range allowedSlots {
		if id == req.TimeSlotID {
			isAllowed = true
			break
		}
	}
	if !isAllowed {
		s.logger.Warn("invalid time slot",
			slog.Uint64("slot_id", uint64(req.TimeSlotID)),
			slog.Any("allowed_slots", allowedSlots),
		)
		return nil, ErrInvalidTimeSlot
	}

	var newBooking *booking.Booking

	// Create booking in transaction
	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		txRepo := s.repo.WithTx(tx)

		// Double-check slot availability with lock
		isBooked, err := txRepo.IsSlotBooked(ctx, req.TechnicianID, dateStr, req.TimeSlotID)
		if err != nil {
			s.logger.Error("failed to check slot booking", slog.String("error", err.Error()))
			return err
		}
		if isBooked {
			s.logger.Warn("slot already booked",
				slog.Uint64("technician_id", uint64(req.TechnicianID)),
				slog.String("date", dateStr),
				slog.Uint64("slot_id", uint64(req.TimeSlotID)),
			)
			return ErrSlotBooked
		}

		// Get technician service details
		techSvc, err := txRepo.GetTechnicianService(ctx, req.TechnicianServiceID)
		if err != nil {
			s.logger.Error("service not found", slog.String("error", err.Error()))
			return ErrServiceNotFound
		}

		// Get and validate customer address
		custAddr, err := txRepo.GetCustomerAddress(ctx, req.AddressID, customerID)
		if err != nil {
			s.logger.Error("address not found", slog.String("error", err.Error()))
			return ErrAddressNotFound
		}

		// Verify service area coverage
		if custAddr.ProvinceID != nil {
			isServing, err := txRepo.IsTechnicianServingProvince(ctx, req.TechnicianID, *custAddr.ProvinceID)
			if err != nil {
				s.logger.Error("failed to check service area", slog.String("error", err.Error()))
				return err
			}
			if !isServing {
				s.logger.Warn("service area not covered",
					slog.Uint64("technician_id", uint64(req.TechnicianID)),
					slog.Uint64("province_id", uint64(*custAddr.ProvinceID)),
				)
				return ErrServiceAreaNotCovered
			}
		}

		// Format address snapshot
		fullAddress := booking.FormatAddressSnapshot(custAddr)
		bookingNumber := utils.GenerateBookingNumber10Digits()

		// Create booking record
		newBooking = &booking.Booking{
			BookingNumber:       bookingNumber,
			CustomerID:          customerID,
			TechnicianID:        req.TechnicianID,
			TechnicianServiceID: req.TechnicianServiceID,
			AddressID:           req.AddressID,
			TimeSlotID:          req.TimeSlotID,
			AppointmentDate:     appointDate,
			RecordedAddress:     fullAddress,
			CustomerNote:        req.CustomerNote,
			Status:              booking.BookingStatusPending,
			PaymentMethod:       booking.PaymentMethodCOD,
			PricingType:         techSvc.PricingType,
		}

		// Set pricing based on type
		if techSvc.PricingType == "FIXED" {
			newBooking.QuotedPriceFixed = techSvc.PriceFixed
			newBooking.FinalPrice = techSvc.PriceFixed
		} else {
			newBooking.QuotedPriceMin = techSvc.PriceMin
			newBooking.QuotedPriceMax = techSvc.PriceMax
		}

		// Create booking
		if err := txRepo.Create(ctx, newBooking); err != nil {
			if strings.Contains(err.Error(), "Duplicate entry") {
				return ErrSlotBooked
			}
			s.logger.Error("failed to create booking", slog.String("error", err.Error()))
			return err
		}

		// Create booking images if any
		if len(req.ImageURLs) > 0 {
			images := make([]booking.BookingImage, 0, len(req.ImageURLs))
			for _, url := range req.ImageURLs {
				images = append(images, booking.BookingImage{
					BookingID: newBooking.ID,
					ImageURL:  url,
				})
			}
			if err := txRepo.CreateImages(ctx, images); err != nil {
				s.logger.Error("failed to create images", slog.String("error", err.Error()))
				return err
			}
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	// Fetch complete booking details
	created, _ := s.repo.FindByID(ctx, newBooking.ID)
	if created == nil {
		created = newBooking
	}

	s.logger.Info("booking created successfully",
		slog.Uint64("booking_id", uint64(created.ID)),
		slog.String("booking_number", created.BookingNumber),
	)

	// Send notification to technician
	if s.notif != nil && created.TechnicianID != 0 {
		s.sendBookingNotification(ctx, created, "BOOKING_CREATED", "มีงานใหม่", "มีลูกค้าจองบริการเข้ามา")
	}

	return created, nil
}

func (s *service) GetBookingDetail(ctx context.Context, bookingID uint) (*booking.Booking, error) {
	return s.repo.FindByID(ctx, bookingID)
}

func (s *service) CancelBooking(ctx context.Context, customerID, bookingID uint, reason string) (*booking.Booking, error) {
	reason = strings.TrimSpace(reason)
	if len(reason) > 255 {
		reason = reason[:255]
	}

	s.logger.Info("cancelling booking",
		slog.Uint64("customer_id", uint64(customerID)),
		slog.Uint64("booking_id", uint64(bookingID)),
		slog.String("reason", reason),
	)

	var updated *booking.Booking

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		txRepo := s.repo.WithTx(tx)

		b, err := txRepo.FindByIDForUpdate(ctx, bookingID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return ErrBookingNotFound
			}
			return err
		}

		if b.CustomerID != customerID {
			s.logger.Warn("forbidden booking access",
				slog.Uint64("customer_id", uint64(customerID)),
				slog.Uint64("booking_customer_id", uint64(b.CustomerID)),
			)
			return ErrForbiddenBooking
		}

		if b.Status != booking.BookingStatusPending && b.Status != booking.BookingStatusAccepted {
			s.logger.Warn("invalid status for cancellation",
				slog.String("current_status", b.Status),
			)
			return ErrBookingIsStartedOrCompleted
		}

		now := time.Now()
		if err := txRepo.UpdateStatus(ctx, bookingID, booking.BookingStatusCancelled, now); err != nil {
			return err
		}

		updated = b
		updated.Status = booking.BookingStatusCancelled
		return nil
	})

	if err != nil {
		return nil, err
	}

	// Fetch complete details
	full, _ := s.repo.FindByID(ctx, bookingID)

	s.logger.Info("booking cancelled",
		slog.Uint64("booking_id", uint64(bookingID)),
	)

	// Send notification
	if s.notif != nil && full != nil {
		s.sendBookingNotification(ctx, full, "BOOKING_CANCELLED", "ลูกค้ากดยกเลิกงาน",
			fmt.Sprintf("ลูกค้าได้ยกเลิกการจองหมายเลข %s", full.BookingNumber))
	}

	return full, nil
}

func (s *service) ListBookings(ctx context.Context, customerID uint, q ListBookingsQuery) ([]booking.Booking, int64, int, int, error) {
	page := q.Page
	limit := q.Limit
	if page <= 0 {
		page = 1
	}
	if limit <= 0 {
		limit = 20
	}

	statuses, err := booking.ParseStatusFilter(q.Status)
	if err != nil {
		return nil, 0, page, limit, err
	}

	items, total, err := s.repo.ListByCustomer(ctx, customerID, statuses, q.StartDate, q.EndDate, (page-1)*limit, limit)
	if err != nil {
		return nil, 0, page, limit, err
	}

	return items, total, page, limit, nil
}

func (s *service) sendBookingNotification(ctx context.Context, b *booking.Booking, nType, title, msg string) {
	data := map[string]any{
		"booking_id":       b.ID,
		"booking_number":   b.BookingNumber,
		"status":           b.Status,
		"appointment_date": booking.FormatDate(b.AppointmentDate),
	}
	_, _ = s.notif.Create(ctx, notification.CreateNotificationInput{
		RecipientRole: notification.RoleTechnician,
		RecipientID:   b.TechnicianID,
		Type:          nType,
		Title:         title,
		Message:       msg,
		EntityType:    "booking",
		EntityID:      b.ID,
		Data:          data,
	})
}
