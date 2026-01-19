package booking

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	address "changsure-core-service/internal/modules/customer_address"
	"changsure-core-service/internal/modules/notification"
	technicianschedule "changsure-core-service/internal/modules/technician_schedule"
	timeslot "changsure-core-service/internal/modules/time_slot"
	"changsure-core-service/pkg/utils"

	"gorm.io/gorm"
)

var (
	ErrSlotBooked            = errors.New("time slot is already booked")
	ErrServiceNotFound       = errors.New("technician service not found")
	ErrAddressNotFound       = errors.New("address not found or invalid ownership")
	ErrInvalidDateFormat     = errors.New("invalid date format")
	ErrTechnicianClosed      = errors.New("technician is not working on this date")
	ErrInvalidTimeSlot       = errors.New("time slot is invalid or changed")
	ErrServiceAreaNotCovered = errors.New("technician does not serve this area")

	ErrBookingNotFound      = errors.New("booking not found")
	ErrForbiddenBooking     = errors.New("forbidden booking")
	ErrInvalidBookingStatus = errors.New("invalid booking status")
	ErrBookingIsStartedOrCompleted = errors.New("cannot cancel booking that is in progress or completed")
	
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

	CreateBooking(ctx context.Context, customerID uint, req CreateBookingRequest) (*Booking, error)
	GetBookingDetail(ctx context.Context, bookingID uint) (*Booking, error)
	CancelBooking(ctx context.Context, customerID, bookingID uint, reason string) (*Booking, error)

	AcceptBooking(ctx context.Context, technicianID, bookingID uint) (*Booking, error)
	RejectBooking(ctx context.Context, technicianID, bookingID uint, reason string) (*Booking, error)

	ListTechnicianBookings(ctx context.Context, technicianID uint, q ListTechnicianBookingsQuery) ([]Booking, int64, int, int, error)
}

type service struct {
	repo         Repository
	timeSlotRepo timeslot.Repository
	scheduleRepo technicianschedule.Repository
	db           *gorm.DB

	notif notification.Service
}

func NewService(repo Repository, timeSlotRepo timeslot.Repository, scheduleRepo technicianschedule.Repository, db *gorm.DB, notif notification.Service) Service {
	return &service{
		repo:         repo,
		timeSlotRepo: timeSlotRepo,
		scheduleRepo: scheduleRepo,
		db:           db,
		notif:        notif,
	}
}

func (s *service) GetAvailableTimeSlots(ctx context.Context, technicianID uint, dateStr string) ([]TimeSlotAvailability, error) {
	if _, err := time.ParseInLocation("2006-01-02", dateStr, bkkLoc); err != nil {
		return nil, ErrInvalidDateFormat
	}

	allSlots, err := s.timeSlotRepo.GetSlotsForTechnician(ctx, technicianID)
	if err != nil {
		return nil, err

	}

	bookedSlotIDs, err := s.repo.GetBookedSlotIDs(ctx, technicianID, dateStr)
	if err != nil {
		return nil, err
	}

	bookedMap := make(map[uint]bool, len(bookedSlotIDs))
	for _, id := range bookedSlotIDs {
		bookedMap[id] = true
	}

	result := make([]TimeSlotAvailability, 0, len(allSlots))
	for _, slot := range allSlots {
		result = append(result, TimeSlotAvailability{
			ID:          slot.ID,
			Label:       fmt.Sprintf("%s - %s", slot.StartTime, slot.EndTime),
			IsAvailable: !bookedMap[slot.ID],
		})
	}

	return result, nil
}

func (s *service) CreateBooking(ctx context.Context, customerID uint, req CreateBookingRequest) (*Booking, error) {

	appointDate, err := time.ParseInLocation("2006-01-02", req.AppointmentDate, bkkLoc)
	if err != nil {
		return nil, ErrInvalidDateFormat
	}
	dateStr := req.AppointmentDate

	weekday := int(appointDate.Weekday())
	workingDays, err := s.scheduleRepo.GetWeeklySchedule(ctx, req.TechnicianID)
	if err != nil {
		return nil, err
	}
	isWorkingDay := false
	if len(workingDays) == 0 {
		isWorkingDay = true
	} else {
		for _, day := range workingDays {
			if day == weekday {
				isWorkingDay = true
				break
			}
		}
	}
	if !isWorkingDay {
		return nil, ErrTechnicianClosed
	}

	leavesMap, err := s.scheduleRepo.GetLeavesByRange(ctx, req.TechnicianID, dateStr, dateStr)
	if err != nil {
		return nil, err
	}
	if leavesMap[dateStr] {
		return nil, ErrTechnicianClosed
	}

	targetSlot, err := s.timeSlotRepo.FindByID(ctx, req.TimeSlotID)
	if err != nil {

		return nil, ErrInvalidTimeSlot
	}

	if targetSlot.TechnicianID != nil && *targetSlot.TechnicianID != req.TechnicianID {
		return nil, ErrInvalidTimeSlot
	}

	if !targetSlot.IsActive {
		return nil, ErrInvalidTimeSlot
	}

	var newBooking *Booking

	err = s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		txRepo := s.repo.WithTx(tx)

		isBooked, err := txRepo.IsSlotBooked(ctx, req.TechnicianID, req.AppointmentDate, req.TimeSlotID)
		if err != nil {
			return err
		}
		if isBooked {
			return ErrSlotBooked
		}

		techSvc, err := txRepo.GetTechnicianService(ctx, req.TechnicianServiceID)
		if err != nil {
			return ErrServiceNotFound
		}

		custAddr, err := txRepo.GetCustomerAddress(ctx, req.AddressID, customerID)
		if err != nil {
			return ErrAddressNotFound
		}

		if custAddr.ProvinceID != nil {
			isServing, err := txRepo.IsTechnicianServingProvince(ctx, req.TechnicianID, *custAddr.ProvinceID)
			if err != nil {
				return err
			}
			if !isServing {
				return ErrServiceAreaNotCovered
			}
		}

		fullAddress := formatAddressSnapshot(custAddr)
		bookingNumber := utils.GenerateBookingNumber()

		newBooking = &Booking{
			BookingNumber:       bookingNumber,
			CustomerID:          customerID,
			TechnicianID:        req.TechnicianID,
			TechnicianServiceID: req.TechnicianServiceID,
			AddressID:           req.AddressID,
			TimeSlotID:          req.TimeSlotID,
			AppointmentDate:     appointDate,
			RecordedAddress:     fullAddress,
			CustomerNote:        req.CustomerNote,
			Status:              BookingStatusPending,
			PaymentMethod:       PaymentMethodCOD,

			PricingType: techSvc.PricingType,
		}

		if techSvc.PricingType == "FIXED" {
			newBooking.QuotedPriceFixed = techSvc.PriceFixed
			newBooking.FinalPrice = techSvc.PriceFixed
		} else {
			newBooking.QuotedPriceMin = techSvc.PriceMin
			newBooking.QuotedPriceMax = techSvc.PriceMax
			newBooking.FinalPrice = nil
		}

		if err := txRepo.Create(ctx, newBooking); err != nil {
			if strings.Contains(err.Error(), "Duplicate entry") || strings.Contains(err.Error(), "unique constraint") {
				return ErrSlotBooked
			}
			return err
		}

		if len(req.ImageURLs) > 0 {
			images := make([]BookingImage, 0, len(req.ImageURLs))
			for _, url := range req.ImageURLs {
				images = append(images, BookingImage{
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

	created, err := s.repo.FindByID(ctx, newBooking.ID)
	if err != nil {
		created = newBooking
	}

	if s.notif != nil && created != nil && created.TechnicianID != 0 {
		data := map[string]any{
			"booking_id":            created.ID,
			"booking_number":        created.BookingNumber,
			"status":                created.Status,
			"customer_id":           created.CustomerID,
			"technician_id":         created.TechnicianID,
			"appointment_date":      created.AppointmentDate.Format("2006-01-02"),
			"time_slot_id":          created.TimeSlotID,
			"technician_service_id": created.TechnicianServiceID,
			"pricing_type":          created.PricingType,
		}

		if created.PricingType == "FIXED" && created.QuotedPriceFixed != nil {
			data["price"] = *created.QuotedPriceFixed
		} else if created.PricingType == "RANGE" {
			data["price_min"] = created.QuotedPriceMin
			data["price_max"] = created.QuotedPriceMax
		}

		_, _ = s.notif.Create(ctx, notification.CreateNotificationInput{
			RecipientRole: notification.RoleTechnician,
			RecipientID:   created.TechnicianID,
			Type:          "BOOKING_CREATED",
			Title:         "มีงานใหม่",
			Message:       "มีลูกค้าจองบริการเข้ามา",
			EntityType:    "booking",
			EntityID:      created.ID,
			Data:          data,
		})
	}

	return created, nil
}

func (s *service) GetBookingDetail(ctx context.Context, bookingID uint) (*Booking, error) {
	return s.repo.FindByID(ctx, bookingID)
}

func (s *service) AcceptBooking(ctx context.Context, technicianID, bookingID uint) (*Booking, error) {
	var updated *Booking

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		txRepo := s.repo.WithTx(tx)

		b, err := txRepo.FindByIDForUpdate(ctx, bookingID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return ErrBookingNotFound
			}
			return err
		}

		if b.TechnicianID != technicianID {
			return ErrForbiddenBooking
		}

		if b.Status != BookingStatusPending {
			return ErrInvalidBookingStatus
		}

		now := time.Now()
		if err := txRepo.UpdateStatus(ctx, bookingID, BookingStatusAccepted, now); err != nil {
			return err
		}

		updated = b
		updated.Status = BookingStatusAccepted
		updated.UpdatedAt = now
		return nil
	})

	if err != nil {
		return nil, err
	}

	full, err := s.repo.FindByID(ctx, bookingID)
	if err != nil {
		full = updated
	}

	if s.notif != nil && full != nil && full.CustomerID != 0 {
		_, _ = s.notif.Create(ctx, notification.CreateNotificationInput{
			RecipientRole: notification.RoleCustomer,
			RecipientID:   full.CustomerID,
			Type:          "BOOKING_ACCEPTED",
			Title:         "ช่างรับงานแล้ว",
			Message:       "ช่างตอบรับการจองของคุณแล้ว",
			EntityType:    "booking",
			EntityID:      full.ID,
			Data: map[string]any{
				"booking_id":       full.ID,
				"booking_number":   full.BookingNumber,
				"status":           full.Status,
				"technician_id":    full.TechnicianID,
				"appointment_date": full.AppointmentDate.Format("2006-01-02"),
			},
		})
	}

	return full, nil
}

func (s *service) RejectBooking(ctx context.Context, technicianID, bookingID uint, reason string) (*Booking, error) {
	reason = strings.TrimSpace(reason)
	if len(reason) > 255 {
		reason = reason[:255]
	}

	var updated *Booking

	err := s.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		txRepo := s.repo.WithTx(tx)

		b, err := txRepo.FindByIDForUpdate(ctx, bookingID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return ErrBookingNotFound
			}
			return err
		}

		if b.TechnicianID != technicianID {
			return ErrForbiddenBooking
		}

		if b.Status != BookingStatusPending {
			return ErrInvalidBookingStatus
		}

		now := time.Now()
		if err := txRepo.UpdateStatus(ctx, bookingID, BookingStatusCancelled, now); err != nil {
			return err
		}

		updated = b
		updated.Status = BookingStatusCancelled
		updated.UpdatedAt = now
		return nil
	})

	if err != nil {
		return nil, err
	}

	full, err := s.repo.FindByID(ctx, bookingID)
	if err != nil {
		full = updated
	}

	if s.notif != nil && full != nil && full.CustomerID != 0 {
		_, _ = s.notif.Create(ctx, notification.CreateNotificationInput{
			RecipientRole: notification.RoleCustomer,
			RecipientID:   full.CustomerID,
			Type:          "BOOKING_REJECTED",
			Title:         "ช่างปฏิเสธงาน",
			Message:       "ช่างปฏิเสธการจองของคุณ",
			EntityType:    "booking",
			EntityID:      full.ID,
			Data: map[string]any{
				"booking_id":       full.ID,
				"booking_number":   full.BookingNumber,
				"status":           full.Status,
				"reason":           reason,
				"technician_id":    full.TechnicianID,
				"appointment_date": full.AppointmentDate.Format("2006-01-02"),
			},
		})
	}

	return full, nil

}

func (s *service) ListTechnicianBookings(
	ctx context.Context,
	technicianID uint,
	q ListTechnicianBookingsQuery,
) ([]Booking, int64, int, int, error) {

	page := q.Page
	limit := q.Limit
	if page <= 0 {
		page = 1
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}

	offset := (page - 1) * limit

	items, total, err := s.repo.ListTechnicianBookings(
		ctx,
		technicianID,
		q.Status,
		q.StartDate,
		q.EndDate,
		offset,
		limit,
	)
	if err != nil {
		return nil, 0, page, limit, err
	}

	return items, total, page, limit, nil
}

func (s *service) CancelBooking(ctx context.Context, customerID, bookingID uint, reason string) (*Booking, error) {
	reason = strings.TrimSpace(reason)
	if len(reason) > 255 {
		reason = reason[:255]
	}

	var updated *Booking

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

		if b.Status != BookingStatusPending && b.Status != BookingStatusAccepted {
			return ErrBookingIsStartedOrCompleted
		}

		now := time.Now()
		if err := txRepo.UpdateStatus(ctx, bookingID, BookingStatusCancelled, now); err != nil {
			return err
		}

		updated = b
		updated.Status = BookingStatusCancelled
		updated.UpdatedAt = now
		return nil
	})

	if err != nil {
		return nil, err
	}

	full, err := s.repo.FindByID(ctx, bookingID)
	if err != nil {
		full = updated
	}

	if s.notif != nil && full != nil && full.TechnicianID != 0 {
		_, _ = s.notif.Create(ctx, notification.CreateNotificationInput{
			RecipientRole: notification.RoleTechnician,
			RecipientID:   full.TechnicianID,
			Type:          "BOOKING_CANCELLED",
			Title:         "ลูกค้ากดยกเลิกงาน",
			Message:       fmt.Sprintf("ลูกค้าได้ยกเลิกการจองหมายเลข %s", full.BookingNumber),
			EntityType:    "booking",
			EntityID:      full.ID,
			Data: map[string]any{
				"booking_id":       full.ID,
				"booking_number":   full.BookingNumber,
				"status":           full.Status,
				"reason":           reason,
				"customer_id":      full.CustomerID,
				"appointment_date": full.AppointmentDate.Format("2006-01-02"),
			},
		})
	}

	return full, nil
}

func formatAddressSnapshot(addr *address.CustomerAddress) string {
	subName := "-"
	distName := "-"
	provName := "-"
	postal := "-"

	if addr.SubDistrict != nil {
		subName = addr.SubDistrict.NameTH
		postal = addr.SubDistrict.PostalCode
	}
	if addr.District != nil {
		distName = addr.District.NameTH
	}
	if addr.Province != nil {
		provName = addr.Province.NameTH
	}

	return fmt.Sprintf("%s หมู่บ้าน %s ซอย %s ถนน %s แขวง %s เขต %s จ. %s %s",
		getValue(addr.HouseNumber),
		getValue(addr.Village),
		getValue(addr.Soi),
		getValue(addr.Road),
		subName,
		distName,
		provName,
		postal,
	)
}

func getValue(s *string) string {
	if s == nil {
		return "-"
	}
	return *s
}
