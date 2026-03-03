package resetpassword

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Repository interface {
	Create(otp *PasswordResetOTP) error
	FindValidOTP(email string, role UserRole, otp string) (*PasswordResetOTP, error)
	MarkUsed(id uuid.UUID) error
	DeleteExpired() error
	InvalidateAll(email string, role UserRole) error
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Create(otp *PasswordResetOTP) error {
	return r.db.Create(otp).Error
}

func (r *repository) FindValidOTP(email string, role UserRole, otp string) (*PasswordResetOTP, error) {
	var record PasswordResetOTP
	err := r.db.
		Where("email = ? AND user_role = ? AND otp = ? AND is_used = false AND expires_at > ?",
			email, role, otp, time.Now()).
		Order("created_at DESC").
		First(&record).Error

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil
	}
	return &record, err
}

func (r *repository) MarkUsed(id uuid.UUID) error {
	return r.db.Model(&PasswordResetOTP{}).
		Where("id = ?", id).
		Update("is_used", true).Error
}

func (r *repository) DeleteExpired() error {
	return r.db.
		Where("expires_at < ? OR is_used = true", time.Now()).
		Delete(&PasswordResetOTP{}).Error
}

func (r *repository) InvalidateAll(email string, role UserRole) error {
	return r.db.Model(&PasswordResetOTP{}).
		Where("email = ? AND user_role = ? AND is_used = false", email, role).
		Update("is_used", true).Error
}
