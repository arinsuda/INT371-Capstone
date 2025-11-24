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
			Error:        err.Error(),
		}
	}

	if err := sqlDB.PingContext(ctx); err != nil {
		return HealthCheck{
			Status:       "unhealthy",
			ResponseTime: time.Since(start).String(),
			Error:        err.Error(),
		}
	}

	return HealthCheck{
		Status:       "healthy",
		ResponseTime: time.Since(start).String(),
		Stats:        d.GetStats(),
	}
}
