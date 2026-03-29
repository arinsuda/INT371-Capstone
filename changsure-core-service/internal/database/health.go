package database

import (
	"context"
	"time"
)

type HealthCheck struct {
	Status       string                 `json:"status"`
	ResponseTime string                 `json:"response_time"`
	Stats        map[string]interface{} `json:"stats,omitempty"`
	Error        string                 `json:"error,omitempty"`
}

func (d *Database) Health() HealthCheck {
	start := time.Now()

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()

	sqlDB, err := d.DB.DB()
	if err != nil {
		return HealthCheck{
			Status:       "unhealthy",
			ResponseTime: time.Since(start).String(),
			Error:        "failed to get underlying db: " + err.Error(),
		}
	}

	if err := sqlDB.PingContext(ctx); err != nil {
		return HealthCheck{
			Status:       "unhealthy",
			ResponseTime: time.Since(start).String(),
			Error:        "db ping failed: " + err.Error(),
		}
	}

	return HealthCheck{
		Status:       "healthy",
		ResponseTime: time.Since(start).String(),
		Stats:        d.GetStats(),
	}
}

func (d *Database) GetStats() map[string]interface{} {
	sqlDB, err := d.DB.DB()
	if err != nil {
		return map[string]interface{}{"error": err.Error()}
	}

	stats := sqlDB.Stats()
	return map[string]interface{}{
		"open_connections":     stats.OpenConnections,
		"in_use":               stats.InUse,
		"idle":                 stats.Idle,
		"wait_count":           stats.WaitCount,
		"wait_duration":        stats.WaitDuration.String(),
		"max_open_connections": stats.MaxOpenConnections,
		"max_idle_closed":      stats.MaxIdleClosed,
		"max_lifetime_closed":  stats.MaxLifetimeClosed,
	}
}
