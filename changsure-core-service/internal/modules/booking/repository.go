package booking

import (
	"context"
	"time"

	address "changsure-core-service/internal/modules/customer_address"
	techService "changsure-core-service/internal/modules/technician_service"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Repository interface {
	WithTx(tx *gorm.DB) Repository

	Create(ctx context.Context, booking *Booking) error
	CreateImages(ctx context.Context, images []BookingImage) error
	FindByID(ctx context.Context, id uint) (*Booking, error)
	FindByIDForUpdate(ctx context.Context, id uint) (*Booking, error)
	UpdateStatus(ctx context.Context, id uint, status string, updatedAt time.Time) error

	GetBookedSlotIDs(ctx context.Context, technicianID uint, date string) ([]uint, error)
	IsSlotBooked(ctx context.Context, technicianID uint, date string, slotID uint) (bool, error)

	GetTechnicianService(ctx context.Context, serviceID uint) (*techService.TechnicianService, error)
	GetCustomerAddress(ctx context.Context, addressID uint, customerID uint) (*address.CustomerAddress, error)
	IsTechnicianServingProvince(ctx context.Context, technicianID uint, provinceID uint) (bool, error)

	ListByCustomer(
		ctx context.Context,
		customerID uint,
		statuses []string,
		startDate string,
		endDate string,
		offset int,
		limit int,
	) ([]Booking, int64, error)

	ListByTechnician(
		ctx context.Context,
		technicianID uint,
		statuses []string,
		startDate string,
		endDate string,
		offset int,
		limit int,
	) ([]Booking, int64, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) WithTx(tx *gorm.DB) Repository {
	return &repository{db: tx}
}

func (r *repository) Create(ctx context.Context, booking *Booking) error {
	return r.db.WithContext(ctx).Create(booking).Error
}

func (r *repository) CreateImages(ctx context.Context, images []BookingImage) error {
	return r.db.WithContext(ctx).Create(&images).Error
}

func (r *repository) FindByID(ctx context.Context, id uint) (*Booking, error) {
	var booking Booking
	err := r.db.WithContext(ctx).
		Preload("Images").
		Preload("TimeSlot").
		Preload("Technician").
		Preload("TechnicianService").
		Preload("TechnicianService.Service").
		First(&booking, id).Error
	if err != nil {
		return nil, err
	}
	return &booking, nil
}

func (r *repository) FindByIDForUpdate(ctx context.Context, id uint) (*Booking, error) {
	var b Booking
	err := r.db.WithContext(ctx).
		Clauses(clause.Locking{Strength: "UPDATE"}).
		First(&b, id).Error
	if err != nil {
		return nil, err
	}
	return &b, nil
}

func (r *repository) UpdateStatus(ctx context.Context, id uint, status string, updatedAt time.Time) error {
	return r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("id = ?", id).
		Updates(map[string]any{
			"status":     status,
			"updated_at": updatedAt,
		}).Error
}

func (r *repository) GetBookedSlotIDs(ctx context.Context, technicianID uint, date string) ([]uint, error) {
	var slotIDs []uint
	err := r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("technician_id = ? AND appointment_date = ? AND status NOT IN ?",
			technicianID,
			date,
			[]string{BookingStatusCancelled, BookingStatusRejected},
		).
		Pluck("time_slot_id", &slotIDs).Error
	return slotIDs, err
}

func (r *repository) IsSlotBooked(ctx context.Context, technicianID uint, date string, slotID uint) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&Booking{}).
		Where("technician_id = ? AND appointment_date = ? AND time_slot_id = ? AND status != ?",
			technicianID, date, slotID, BookingStatusCancelled).
		Count(&count).Error
	return count > 0, err
}

func (r *repository) GetTechnicianService(ctx context.Context, serviceID uint) (*techService.TechnicianService, error) {
	var svc techService.TechnicianService
	if err := r.db.WithContext(ctx).First(&svc, serviceID).Error; err != nil {
		return nil, err
	}
	return &svc, nil
}

func (r *repository) GetCustomerAddress(ctx context.Context, addressID uint, customerID uint) (*address.CustomerAddress, error) {
	var addr address.CustomerAddress
	if err := r.db.WithContext(ctx).
		Preload("Province").
		Preload("District").
		Preload("SubDistrict").
		Where("id = ? AND customer_id = ?", addressID, customerID).
		First(&addr).Error; err != nil {
		return nil, err
	}
	return &addr, nil
}

func (r *repository) IsTechnicianServingProvince(ctx context.Context, technicianID uint, provinceID uint) (bool, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Table("technician_service_areas").
		Where("technician_id = ? AND province_id = ?", technicianID, provinceID).
		Count(&count).Error

	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *repository) ListByCustomer(
	ctx context.Context,
	customerID uint,
	statuses []string,
	startDate string,
	endDate string,
	offset int,
	limit int,
) ([]Booking, int64, error) {

	q := r.db.WithContext(ctx).Model(&Booking{}).
		Where("customer_id = ?", customerID)

	if len(statuses) > 0 {
		q = q.Where("status IN ?", statuses)
	}

	if startDate != "" && endDate != "" {
		q = q.Where("appointment_date BETWEEN ? AND ?", startDate, endDate)
	} else if startDate != "" {
		q = q.Where("appointment_date >= ?", startDate)
	} else if endDate != "" {
		q = q.Where("appointment_date <= ?", endDate)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var bookings []Booking
	err := q.
		Preload("Images").
		Preload("TimeSlot").
		Preload("Technician").
		Preload("TechnicianService").
		Preload("TechnicianService.Service").
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&bookings).Error

	if err != nil {
		return nil, 0, err
	}

	return bookings, total, nil
}

func (r *repository) ListByTechnician(
	ctx context.Context,
	technicianID uint,
	statuses []string,
	startDate string,
	endDate string,
	offset int,
	limit int,
) ([]Booking, int64, error) {

	q := r.db.WithContext(ctx).Model(&Booking{}).
		Where("technician_id = ?", technicianID)

	if len(statuses) > 0 {
		q = q.Where("status IN ?", statuses)
	}

	if startDate != "" && endDate != "" {
		q = q.Where("appointment_date BETWEEN ? AND ?", startDate, endDate)
	} else if startDate != "" {
		q = q.Where("appointment_date >= ?", startDate)
	} else if endDate != "" {
		q = q.Where("appointment_date <= ?", endDate)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	var bookings []Booking
	err := q.
		Preload("Images").
		Preload("TimeSlot").
		Preload("Technician").
		Preload("TechnicianService").
		Preload("TechnicianService.Service").
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&bookings).Error

	if err != nil {
		return nil, 0, err
	}

	return bookings, total, nil
}
