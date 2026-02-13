package customerbooking

import (
	"context"
	"errors"
	"fmt"
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

var bkkLoc *time.Location

func init() {
	var err error
	bkkLoc, err = time.LoadLocation("Asia/Bangkok")
	if err != nil {
		bkkLoc = time.Local
	}
}

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
}

func NewService(
	repo booking.Repository,
	timeSlotRepo timeslot.Repository,
	calendarRepo techniciancalendar.Repository,
	db *gorm.DB,
	notif notification.Service,
) Service {
	return &service{
		repo:         repo,
		timeSlotRepo: timeSlotRepo,
		calendarRepo: calendarRepo,
		db:           db,
		notif:        notif,
	}
}

func (s *service) GetAvailableTimeSlots(ctx context.Context, technicianID uint, dateStr string) ([]TimeSlotAvailability, error) {
	parsedDate, err := time.ParseInLocation("2006-01-02", dateStr, bkkLoc)
	if err != nil {
		return nil, ErrInvalidDateFormat
	}

	// Check if technician is closed on this date
	dateStatus, err := s.calendarRepo.GetCalendarDatesByRange(ctx, technicianID, parsedDate, parsedDate)
	if err != nil {
		return nil, err
	}
	if isOpen, exists := dateStatus[dateStr]; exists && !isOpen {
		return []TimeSlotAvailability{}, nil
	}

	// Get slots configured for this specific date
	activeSlotIDs, err := s.calendarRepo.GetTimeSlotsForDate(ctx, technicianID, &parsedDate)
	if err != nil {
		return nil, err
	}

	// If no slots configured for this date, use default slots
	if len(activeSlotIDs) == 0 {
		activeSlotIDs, err = s.calendarRepo.GetTimeSlotsForDate(ctx, technicianID, nil)
		if err != nil {
			return nil, err
		}
	}

	// If still no slots (not even default), return empty
	if len(activeSlotIDs) == 0 {
		return []TimeSlotAvailability{}, nil
	}

	// Get all active system time slots
	allActiveSlots, err := s.timeSlotRepo.FindActive(ctx)
	if err != nil {
		return nil, err
	}

	// Get booked slots for this date
	bookedSlotIDs, err := s.repo.GetBookedSlotIDs(ctx, technicianID, dateStr)
	if err != nil {
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

	// Build response - only include slots that are both active AND configured for this technician
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

	return result, nil
}

func (s *service) CreateBooking(ctx context.Context, customerID uint, req CreateBookingRequest) (*booking.Booking, error) {
	appointDate, err := time.ParseInLocation("2006-01-02", req.AppointmentDate, bkkLoc)
	if err != nil {
		return nil, ErrInvalidDateFormat
	}
	dateStr := req.AppointmentDate

	// Check if technician is closed on this date
	dateStatus, err := s.calendarRepo.GetCalendarDatesByRange(ctx, req.TechnicianID, appointDate, appointDate)
	if err != nil {
		return nil, err
	}
	if isOpen, exists := dateStatus[dateStr]; exists && !isOpen {
		return nil, ErrTechnicianClosed
	}

	// Get allowed slots for this date (specific date first, then default)
	allowedSlots, err := s.calendarRepo.GetTimeSlotsForDate(ctx, req.TechnicianID, &appointDate)
	if err != nil {
		return nil, err
	}
	if len(allowedSlots) == 0 {
		allowedSlots, err = s.calendarRepo.GetTimeSlotsForDate(ctx, req.TechnicianID, nil)
		if err != nil {
			return nil, err
		}
	}

	// Verify the requested time slot is allowed
	isAllowed := false
	for _, id := range allowedSlots {
		if id == req.TimeSlotID {
			isAllowed = true
			break
		}
	}
	if !isAllowed {
		return nil, ErrInvalidTimeSlot
	}

	var newBooking *booking.Booking

	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		txRepo := s.repo.WithTx(tx)

		// Double-check slot availability within transaction
		isBooked, err := txRepo.IsSlotBooked(ctx, req.TechnicianID, req.AppointmentDate, req.TimeSlotID)
		if err != nil {
			return err
		}
		if isBooked {
			return ErrSlotBooked
		}

		// Get technician service details
		techSvc, err := txRepo.GetTechnicianService(ctx, req.TechnicianServiceID)
		if err != nil {
			return ErrServiceNotFound
		}

		// Get customer address details
		custAddr, err := txRepo.GetCustomerAddress(ctx, req.AddressID, customerID)
		if err != nil {
			return ErrAddressNotFound
		}

		// Verify technician serves this province
		if custAddr.ProvinceID != nil {
			isServing, err := txRepo.IsTechnicianServingProvince(ctx, req.TechnicianID, *custAddr.ProvinceID)
			if err != nil {
				return err
			}
			if !isServing {
				return ErrServiceAreaNotCovered
			}
		}

		// Create booking
		fullAddress := booking.FormatAddressSnapshot(custAddr)
		bookingNumber := utils.GenerateBookingNumber10Digits()

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

		if techSvc.PricingType == "FIXED" {
			newBooking.QuotedPriceFixed = techSvc.PriceFixed
			newBooking.FinalPrice = techSvc.PriceFixed
		} else {
			newBooking.QuotedPriceMin = techSvc.PriceMin
			newBooking.QuotedPriceMax = techSvc.PriceMax
		}

		if err := txRepo.Create(ctx, newBooking); err != nil {
			if strings.Contains(err.Error(), "Duplicate entry") {
				return ErrSlotBooked
			}
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
			return ErrForbiddenBooking
		}

		if b.Status != booking.BookingStatusPending && b.Status != booking.BookingStatusAccepted {
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

	full, _ := s.repo.FindByID(ctx, bookingID)
	if s.notif != nil && full != nil {
		s.sendBookingNotification(ctx, full, "BOOKING_CANCELLED", "ลูกค้ากดยกเลิกงาน", fmt.Sprintf("ลูกค้าได้ยกเลิกการจองหมายเลข %s", full.BookingNumber))
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
		"appointment_date": b.AppointmentDate.Format("2006-01-02"),
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
