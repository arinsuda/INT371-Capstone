package jobs

import (
	"context"
	"log"
	"time"

	"gorm.io/gorm"
)

const (
	banCheckInterval = 24 * time.Hour
	banGracePeriod   = 30 * 24 * time.Hour
)

type technicianModel struct{}

func (technicianModel) TableName() string { return "technicians" }

type TechnicianBanJob struct {
	db     *gorm.DB
	logger *log.Logger
}

func NewTechnicianBanJob(db *gorm.DB, logger *log.Logger) *TechnicianBanJob {
	if logger == nil {
		logger = log.Default()
	}
	return &TechnicianBanJob{db: db, logger: logger}
}

func (j *TechnicianBanJob) Start(ctx context.Context) {
	j.logger.Printf("[TechnicianBanJob] started, interval=%v, grace_period=%v",
		banCheckInterval, banGracePeriod)

	j.run(ctx)

	ticker := time.NewTicker(banCheckInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			j.logger.Printf("[TechnicianBanJob] stopped")
			return
		case <-ticker.C:
			j.run(ctx)
		}
	}
}

func (j *TechnicianBanJob) run(ctx context.Context) {
	cutoff := time.Now().Add(-banGracePeriod)

	result := j.db.WithContext(ctx).
		Model(&technicianModel{}).
		Where(
			"banned_at IS NOT NULL AND banned_at <= ? AND is_available = ? AND deleted_at IS NULL",
			cutoff, true,
		).
		Update("is_available", false)

	if result.Error != nil {
		j.logger.Printf("[TechnicianBanJob] ERROR: %v", result.Error)
		return
	}

	if result.RowsAffected > 0 {
		j.logger.Printf("[TechnicianBanJob] banned %d technician(s) after grace period (cutoff: %s)",
			result.RowsAffected, cutoff.Format(time.RFC3339))
	}
}
