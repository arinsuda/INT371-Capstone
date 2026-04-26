package emailverification

// import (
// 	"context"
// 	"errors"
// 	"time"

// 	"gorm.io/gorm"
// )

// type Repository interface {
// 	Create(ctx context.Context, otp *EmailOTP) error
// 	FindLatestPending(ctx context.Context, email, role string) (*EmailOTP, error)
// 	MarkVerified(ctx context.Context, id uint) error
// 	IncrementAttempt(ctx context.Context, id uint) error
// 	DeletePendingByEmail(ctx context.Context, email, role string) error
// }

// type repository struct {
// 	db *gorm.DB
// }

// func NewRepository(db *gorm.DB) Repository {
// 	return &repository{db: db}
// }

// func (r *repository) Create(ctx context.Context, otp *EmailOTP) error {
// 	return r.db.WithContext(ctx).Create(otp).Error
// }

// func (r *repository) FindLatestPending(ctx context.Context, email, role string) (*EmailOTP, error) {
// 	var otp EmailOTP
// 	err := r.db.WithContext(ctx).
// 		Where("email = ? AND role = ? AND verified_at IS NULL", email, role).
// 		Order("created_at DESC").
// 		First(&otp).Error
// 	if errors.Is(err, gorm.ErrRecordNotFound) {
// 		return nil, nil
// 	}
// 	return &otp, err
// }

// func (r *repository) MarkVerified(ctx context.Context, id uint) error {
// 	now := time.Now()
// 	return r.db.WithContext(ctx).
// 		Model(&EmailOTP{}).
// 		Where("id = ?", id).
// 		Update("verified_at", now).Error
// }

// func (r *repository) IncrementAttempt(ctx context.Context, id uint) error {
// 	return r.db.WithContext(ctx).
// 		Model(&EmailOTP{}).
// 		Where("id = ?", id).
// 		UpdateColumn("attempt_count", gorm.Expr("attempt_count + 1")).Error
// }

// func (r *repository) DeletePendingByEmail(ctx context.Context, email, role string) error {
// 	return r.db.WithContext(ctx).
// 		Where("email = ? AND role = ? AND verified_at IS NULL", email, role).
// 		Delete(&EmailOTP{}).Error
// }