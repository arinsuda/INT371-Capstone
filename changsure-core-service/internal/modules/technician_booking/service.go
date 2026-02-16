package technicianbooking

import (
	"context"
	"errors"
	"strings"
	"time"

	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/modules/notification"

	"gorm.io/gorm"
)

var (
	ErrBookingNotFound      = errors.New("booking not found")
	ErrForbiddenBooking     = errors.New("forbidden booking")
	ErrInvalidBookingStatus = errors.New("invalid booking status")
)

type Service interface {
	AcceptBooking(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error)
	RejectBooking(ctx context.Context, technicianID, bookingID uint, reason string) (*booking.Booking, error)

	StartJob(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error)
	CompleteJob(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error)

	ListBookings(ctx context.Context, technicianID uint, q ListBookingsQuery) ([]booking.Booking, int64, int, int, error)
	GetBookingByID(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error)
}

type service struct {
	repo  booking.Repository
	db    *gorm.DB
	notif notification.Service
}

func NewService(repo booking.Repository, db *gorm.DB, notif notification.Service) Service {
	return &service{
		repo:  repo,
		db:    db,
		notif: notif,
	}
}

func (s *service) AcceptBooking(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error) {
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

		if b.TechnicianID != technicianID {
			return ErrForbiddenBooking
		}

		if b.Status != booking.BookingStatusPending {
			return ErrInvalidBookingStatus
		}

		now := time.Now()
		if err := txRepo.UpdateStatus(ctx, bookingID, booking.BookingStatusAccepted, now); err != nil {
			return err
		}

		updated = b
		updated.Status = booking.BookingStatusAccepted
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
			Title:         "ช่างรับงานเรียบร้อยแล้ว 👷‍♂️✨",
			Message:       "ช่างได้ยืนยันรับงานบริการของคุณแล้ว คุณสามารถติดตามการดำเนินงานของช่างผ่าน หน้า “ติดตามสถานะ” ได้แล้วในตอนนี้ กรุณาตรวจสอบรายละเอียดวัน–เวลา และรอการติดต่อจากช่างผ่านแชทในแอป",
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

func (s *service) RejectBooking(ctx context.Context, technicianID, bookingID uint, reason string) (*booking.Booking, error) {
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

		if b.TechnicianID != technicianID {
			return ErrForbiddenBooking
		}

		if b.Status != booking.BookingStatusPending &&
			b.Status != booking.BookingStatusAccepted {
			return ErrInvalidBookingStatus
		}

		now := time.Now()
		if err := txRepo.UpdateStatus(ctx, bookingID, booking.BookingStatusRejected, now); err != nil {
			return err
		}

		updated = b
		updated.Status = booking.BookingStatusRejected
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

func (s *service) StartJob(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error) {
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

		if b.TechnicianID != technicianID {
			return ErrForbiddenBooking
		}

		if b.Status != booking.BookingStatusAccepted {
			return ErrInvalidBookingStatus
		}

		now := time.Now()
		if err := txRepo.UpdateStatus(ctx, bookingID, booking.BookingStatusInProgress, now); err != nil {
			return err
		}

		updated = b
		updated.Status = booking.BookingStatusInProgress
		updated.UpdatedAt = now
		return nil
	})

	if err != nil {
		return nil, err
	}

	s.sendNotification(ctx, updated, "JOB_STARTED", "ช่างเริ่มปฏิบัติงานแล้ว", "ช่างได้เริ่มดำเนินการตามขั้นตอนแล้ว")

	return s.repo.FindByID(ctx, bookingID)
}

func (s *service) CompleteJob(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error) {
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

		if b.TechnicianID != technicianID {
			return ErrForbiddenBooking
		}

		if b.Status != booking.BookingStatusInProgress {
			return ErrInvalidBookingStatus
		}

		now := time.Now()

		if err := txRepo.UpdateStatus(ctx, bookingID, booking.BookingStatusWaitingPayment, now); err != nil {
			return err
		}

		updated = b
		updated.Status = booking.BookingStatusWaitingPayment
		updated.UpdatedAt = now
		return nil
	})

	if err != nil {
		return nil, err
	}

	s.sendNotification(ctx, updated, "JOB_COMPLETED", "ดำเนินการเสร็จสิ้น", "กรุณาตรวจสอบและชำระค่าบริการ")

	return s.repo.FindByID(ctx, bookingID)
}

func (s *service) sendNotification(ctx context.Context, b *booking.Booking, notifType, title, message string) {
	if s.notif != nil && b != nil && b.CustomerID != 0 {
		_, _ = s.notif.Create(ctx, notification.CreateNotificationInput{
			RecipientRole: notification.RoleCustomer,
			RecipientID:   b.CustomerID,
			Type:          notifType,
			Title:         title,
			Message:       message,
			EntityType:    "booking",
			EntityID:      b.ID,
			Data: map[string]any{
				"booking_id":       b.ID,
				"booking_number":   b.BookingNumber,
				"status":           b.Status,
				"technician_id":    b.TechnicianID,
				"appointment_date": b.AppointmentDate.Format("2006-01-02"),
			},
		})
	}
}

func (s *service) ListBookings(
	ctx context.Context,
	technicianID uint,
	q ListBookingsQuery,
) ([]booking.Booking, int64, int, int, error) {

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

	statuses, err := booking.ParseStatusFilter(q.Status)
	if err != nil {
		return nil, 0, page, limit, err
	}

	items, total, err := s.repo.ListByTechnician(
		ctx,
		technicianID,
		statuses,
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

func (s *service) GetBookingByID(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error) {
	b, err := s.repo.FindByID(ctx, bookingID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrBookingNotFound
		}
		return nil, err
	}

	if b.TechnicianID != technicianID {
		return nil, ErrForbiddenBooking
	}

	return b, nil
}
