package auth

import (
	"context"
	"log/slog"
	"time"

	"gorm.io/gorm"

	"changsure-core-service/internal/modules/technician"
)

type Cleaner struct {
	db             *gorm.DB
	tokenRepo      TokenRepository
	expireDuration time.Duration
	logger         *slog.Logger
}

func NewCleaner(db *gorm.DB, tokenRepo TokenRepository, expireDuration time.Duration, logger *slog.Logger) *Cleaner {
	if logger == nil {
		logger = slog.Default()
	}
	return &Cleaner{
		db:             db,
		tokenRepo:      tokenRepo,
		expireDuration: expireDuration,
		logger:         logger.With("job", "auth_cleaner"),
	}
}

func (c *Cleaner) Run(ctx context.Context) {
	c.cleanUnverifiedTechnicians(ctx)
	c.cleanExpiredTokens(ctx)
}

func (c *Cleaner) cleanUnverifiedTechnicians(ctx context.Context) {
	cutoff := time.Now().Add(-c.expireDuration)

	var targets []technician.Technician
	if err := c.db.WithContext(ctx).
		Where("is_verified = ? AND created_at < ?", false, cutoff).
		Select("id, email, created_at").
		Find(&targets).Error; err != nil {
		c.logger.Error("query unverified technicians failed", "error", err)
		return
	}
	if len(targets) == 0 {
		c.logger.Info("no unverified technicians to clean up")
		return
	}

	err := c.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		for _, t := range targets {
			if err := tx.Delete(&technician.Technician{}, t.ID).Error; err != nil {
				return err
			}
			c.logger.Info("deleted unverified technician",
				"id", t.ID,
				"email", t.Email,
				"age_days", int(time.Since(t.CreatedAt).Hours()/24),
			)
		}
		return nil
	})
	if err != nil {
		c.logger.Error("cleanup transaction failed", "error", err)
		return
	}
	c.logger.Info("unverified technician cleanup done", "deleted", len(targets))
}

func (c *Cleaner) cleanExpiredTokens(ctx context.Context) {
	if err := c.tokenRepo.DeleteExpired(ctx); err != nil {
		c.logger.Error("delete expired tokens failed", "error", err)
		return
	}
	c.logger.Info("expired refresh tokens cleaned")
}

func (c *Cleaner) StartBackground(ctx context.Context, interval time.Duration) {
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				c.Run(ctx)
			case <-ctx.Done():
				c.logger.Info("auth cleaner stopped")
				return
			}
		}
	}()
}
