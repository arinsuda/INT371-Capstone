package technicianbooking

import (
	"context"
	"errors"
	"strings"
	"time"

	"changsure-core-service/internal/modules/booking"
	"changsure-core-service/internal/modules/notification"
	"changsure-core-service/internal/modules/technician"

	"gorm.io/gorm"
)

var (
	ErrBookingNotFound      = errors.New("booking not found")
	ErrForbiddenBooking     = errors.New("forbidden booking")
	ErrInvalidBookingStatus = errors.New("invalid booking status transition")
	ErrTechnicianNotFound   = errors.New("technician not found")
)

type Service interface {
	UpdateStatus(ctx context.Context, technicianID, bookingID uint, req UpdateBookingStatusRequest) (*booking.Booking, error)
	ListBookings(ctx context.Context, technicianID uint, q ListBookingsQuery) ([]booking.Booking, int64, int, int, error)
	GetBookingByID(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error)
}

type service struct {
	repo     booking.Repository
	db       *gorm.DB
	notif    notification.Service
	techRepo technician.Repository
}

func NewService(repo booking.Repository, db *gorm.DB, notif notification.Service, techRepo technician.Repository) Service {
	return &service{
		repo:     repo,
		db:       db,
		notif:    notif,
		techRepo: techRepo,
	}
}

func (s *service) UpdateStatus(
	ctx context.Context,
	technicianID, bookingID uint,
	req UpdateBookingStatusRequest,
) (*booking.Booking, error) {
	if err := s.verifyTechnicianExists(ctx, technicianID); err != nil {
		return nil, err
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

		if !req.IsAllowedFrom(b.Status) {
			return ErrInvalidBookingStatus
		}

		targetStatus := s.toBookingStatus(req.Status)
		now := time.Now()

		if err := txRepo.UpdateStatus(ctx, bookingID, targetStatus, now); err != nil {
			return err
		}

		updated = b
		updated.Status = targetStatus
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

	go s.sendStatusNotification(ctx, full, req.Status, strings.TrimSpace(req.Reason))

	return full, nil
}

func (s *service) toBookingStatus(status string) string {
	switch status {
	case BookingStatusAccepted:
		return booking.BookingStatusAccepted
	case BookingStatusRejected:
		return booking.BookingStatusRejected
	case BookingStatusInProgress:
		return booking.BookingStatusInProgress
	case BookingStatusWaitingPayment:
		return booking.BookingStatusWaitingPayment
	default:
		return status
	}
}

func (s *service) sendStatusNotification(ctx context.Context, b *booking.Booking, targetStatus, reason string) {
	if s.notif == nil || b == nil || b.CustomerID == 0 {
		return
	}

	var (
		notifType string
		title     string
		message   string
	)

	switch targetStatus {
	case BookingStatusAccepted:
		notifType = "BOOKING_ACCEPTED"
		title = "ช่างรับงานเรียบร้อยแล้ว"
		message = "ช่างได้ยืนยันรับงานบริการของคุณแล้ว กรุณาตรวจสอบรายละเอียดวัน–เวลา"

	case BookingStatusRejected:

		notifType = "BOOKING_REJECTED"
		title = "ช่างปฏิเสธงาน"
		message = "ช่างปฏิเสธการจองของคุณ"
		if reason != "" {
			message += " เหตุผล: " + reason
		}

	case BookingStatusInProgress:
		notifType = "JOB_STARTED"
		title = "ช่างเริ่มปฏิบัติงานแล้ว"
		message = "ช่างได้เริ่มดำเนินการตามขั้นตอนแล้ว"

	case BookingStatusWaitingPayment:
		notifType = "JOB_COMPLETED"
		title = "ดำเนินการเสร็จสิ้น"
		message = "กรุณาตรวจสอบและชำระค่าบริการ"

	default:
		return
	}

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

func (s *service) ListBookings(ctx context.Context, technicianID uint, q ListBookingsQuery) ([]booking.Booking, int64, int, int, error) {
	if err := s.verifyTechnicianExists(ctx, technicianID); err != nil {
		return nil, 0, 0, 0, err
	}

	page, limit := normalizePagination(q.Page, q.Limit)
	offset := (page - 1) * limit

	statuses, err := booking.ParseStatusFilter(q.Status)
	if err != nil {
		return nil, 0, page, limit, err
	}

	items, total, err := s.repo.ListByTechnician(ctx, technicianID, statuses, q.StartDate, q.EndDate, offset, limit)
	if err != nil {
		return nil, 0, page, limit, err
	}

	return items, total, page, limit, nil
}

func (s *service) GetBookingByID(ctx context.Context, technicianID, bookingID uint) (*booking.Booking, error) {
	if err := s.verifyTechnicianExists(ctx, technicianID); err != nil {
		return nil, err
	}

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

func (s *service) verifyTechnicianExists(ctx context.Context, technicianID uint) error {
	var count int64
	err := s.db.WithContext(ctx).
		Table("technicians").
		Where("id = ?", technicianID).
		Count(&count).Error
	if err != nil {
		return err
	}
	if count == 0 {
		return ErrTechnicianNotFound
	}
	return nil
}

func normalizePagination(page, limit int) (int, int) {
	if page <= 0 {
		page = 1
	}
	if limit <= 0 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	return page, limit
}
