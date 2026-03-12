package jobs

import (
	"context"
	"log"
	"time"

	"gorm.io/gorm"
)

const (
	qrExpiryMinutes = 15
	cleanupInterval = 5 * time.Minute
)

type CleanupJob struct {
	db     *gorm.DB
	logger *log.Logger
}

func NewCleanupJob(db *gorm.DB, logger *log.Logger) *CleanupJob {
	if logger == nil {
		logger = log.Default()
	}
	return &CleanupJob{db: db, logger: logger}
}

func (j *CleanupJob) Start(ctx context.Context) {
	j.logger.Printf("[CleanupJob] started, interval=%v, qr_expiry=%d min",
		cleanupInterval, qrExpiryMinutes)

	j.run(ctx)

	ticker := time.NewTicker(cleanupInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			j.logger.Printf("[CleanupJob] stopped")
			return
		case <-ticker.C:
			j.run(ctx)
		}
	}
}

func (j *CleanupJob) run(ctx context.Context) {
	cutoff := time.Now().Add(-time.Duration(qrExpiryMinutes) * time.Minute)

	result := j.db.WithContext(ctx).
		Model(&paymentTransactionModel{}).
		Where("status = ? AND created_at < ?", "pending", cutoff).
		Update("status", "expired")

	if result.Error != nil {
		j.logger.Printf("[CleanupJob] ERROR: %v", result.Error)
		return
	}

	if result.RowsAffected > 0 {
		j.logger.Printf("[CleanupJob] expired %d pending transactions (cutoff: %s)",
			result.RowsAffected, cutoff.Format(time.RFC3339))
	}
}

type paymentTransactionModel struct{}

func (paymentTransactionModel) TableName() string { return "payment_transactions" }
