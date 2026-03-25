package technician

import (
	"context"
	"errors"

	"gorm.io/gorm"
)

type Repository interface {
	FindByID(ctx context.Context, id uint) (*Technician, error)
	FindByEmail(ctx context.Context, email string) (*Technician, error)
	FindByPhone(ctx context.Context, phone string) (*Technician, error)
	Create(ctx context.Context, m *Technician) error
	Update(ctx context.Context, m *Technician) error

	ExistsByID(ctx context.Context, id uint) (bool, error)
	ExistsByEmail(ctx context.Context, email string) (bool, error)

	GetAll(ctx context.Context, limit, offset int) ([]TechnicianWithVerification, error)
	Count(ctx context.Context) (int64, error)
	GetSummaryStats(ctx context.Context) (*TechnicianSummaryStats, error)

	GetStats(ctx context.Context, techID uint) (*TechnicianStats, error)
	UpdateIDCardImage(ctx context.Context, techID uint, imageKey string) error
	UpdateVerificationStatus(ctx context.Context, techID uint, status VerificationStatus) error
}

type repository struct{ db *gorm.DB }

func NewRepository(db *gorm.DB) Repository { return &repository{db: db} }

func (r *repository) GetStats(ctx context.Context, techID uint) (*TechnicianStats, error) {
	var stats TechnicianStats
	err := r.db.WithContext(ctx).
		Table("technician_stats").
		Where("technician_id = ?", techID).
		Scan(&stats).Error
	return &stats, err
}

func (r *repository) UpdateIDCardImage(ctx context.Context, techID uint, imageKey string) error {
	return r.db.WithContext(ctx).
		Model(&Technician{}).
		Where("id = ?", techID).
		Update("id_card_image_url", imageKey).Error
}

func (r *repository) UpdateVerificationStatus(ctx context.Context, techID uint, status VerificationStatus) error {
	updates := map[string]any{
		"verification_status": status,
	}
	if status == StatusPassed {
		updates["verified_at"] = gorm.Expr("NOW()")
	} else {
		updates["verified_at"] = nil
	}
	return r.db.WithContext(ctx).
		Model(&Technician{}).
		Where("id = ?", techID).
		Updates(updates).Error
}

func (r *repository) FindByID(ctx context.Context, id uint) (*Technician, error) {
	var m Technician
	err := r.db.WithContext(ctx).
		Preload("Services", "is_active = ?", true).
		Preload("Services.Service").
		Preload("ServiceAreas", "is_active = ?", true).
		Preload("ServiceAreas.Province").
		First(&m, id).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &m, nil
}

func (r *repository) FindByEmail(ctx context.Context, email string) (*Technician, error) {
	var m Technician
	if err := r.db.WithContext(ctx).Where("email = ?", email).First(&m).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &m, nil
}

func (r *repository) FindByPhone(ctx context.Context, phone string) (*Technician, error) {
	var m Technician
	if err := r.db.WithContext(ctx).Where("phone = ?", phone).First(&m).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}
	return &m, nil
}

func (r *repository) Create(ctx context.Context, m *Technician) error {
	return r.db.WithContext(ctx).Create(m).Error
}

func (r *repository) Update(ctx context.Context, m *Technician) error {
	return r.db.WithContext(ctx).Save(m).Error
}

func (r *repository) ExistsByID(ctx context.Context, id uint) (bool, error) {
	var m Technician
	if err := r.db.WithContext(ctx).
		Select("id").
		First(&m, id).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

func (r *repository) ExistsByEmail(ctx context.Context, email string) (bool, error) {
	var m Technician
	if err := r.db.WithContext(ctx).
		Select("id").
		Where("email = ?", email).
		First(&m).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

type TechnicianWithVerification struct {
	Technician
	WarningCount int64 `gorm:"column:warning_count"`
}

func (r *repository) GetAll(ctx context.Context, limit, offset int) ([]TechnicianWithVerification, error) {
	var list []TechnicianWithVerification
	err := r.db.WithContext(ctx).
		Model(&Technician{}).
		Select(`technicians.*,
            COALESCE(
                (SELECT COUNT(*) FROM technician_post_reports
                 WHERE technician_id = technicians.id AND severity = 'WARNING'),
            0) AS warning_count`).
		Where("technicians.deleted_at IS NULL").
		Preload("ServiceAreas", "is_active = ?", true).
		Preload("ServiceAreas.Province").
		Preload("Services", "is_active = ?", true).
		Preload("Services.Service").
		Preload("Services.Service.Category").
		Order("technicians.created_at DESC").
		Limit(limit).
		Offset(offset).
		Find(&list).Error
	return list, err
}

func (r *repository) Count(ctx context.Context) (int64, error) {
	var count int64
	err := r.db.WithContext(ctx).
		Model(&Technician{}).
		Where("deleted_at IS NULL").
		Count(&count).Error
	return count, err
}

func (r *repository) SyncStats(ctx context.Context, techID uint) error {
	return r.db.WithContext(ctx).Exec(`
		UPDATE technicians t
		SET
			total_jobs = (
				SELECT COUNT(*) FROM bookings
				WHERE technician_id = ? AND status = 'COMPLETED'
			),
			rating_count = (
				SELECT COUNT(*) FROM reviews rv
				JOIN bookings b ON b.id = rv.booking_id
				WHERE b.technician_id = ?
			),
			rating_avg = (
				SELECT COALESCE(ROUND(AVG(rv.rating), 2), 0.00)
				FROM reviews rv
				JOIN bookings b ON b.id = rv.booking_id
				WHERE b.technician_id = ?
			)
		WHERE t.id = ?
	`, techID, techID, techID, techID).Error
}

func (r *repository) GetSummaryStats(ctx context.Context) (*TechnicianSummaryStats, error) {
	var stats TechnicianSummaryStats

	if err := r.db.WithContext(ctx).
		Model(&Technician{}).
		Where("deleted_at IS NULL").
		Count(&stats.Total).Error; err != nil {
		return nil, err
	}

	if err := r.db.WithContext(ctx).
		Model(&Technician{}).
		Where("deleted_at IS NULL AND verification_status = ?", StatusPassed).
		Count(&stats.VerifiedCount).Error; err != nil {
		return nil, err
	}

	if err := r.db.WithContext(ctx).
		Model(&Technician{}).
		Where("verification_status IN ?", []VerificationStatus{
			StatusPending,
			StatusReview,
		}).
		Count(&stats.PendingCount).Error; err != nil {
		return nil, err
	}

	return &stats, nil
}
