package backgroundjob

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Repository interface {
	Enqueue(ctx context.Context, jobType JobType, payload any) (*BackgroundJob, error)

	PollNext(ctx context.Context, jobType JobType) (*BackgroundJob, error)

	MarkProcessing(ctx context.Context, id uint) error

	MarkDone(ctx context.Context, id uint) error

	MarkFailed(ctx context.Context, id uint, errMsg string) (willRetry bool, err error)

	MarkPendingManual(ctx context.Context, id uint) error

	FlagStaleJobs(ctx context.Context, jobType JobType, olderThan time.Duration) ([]BackgroundJob, error)

	GetByID(ctx context.Context, id uint) (*BackgroundJob, error)

	ListByStatus(ctx context.Context, jobType JobType, status JobStatus, page, pageSize int) ([]BackgroundJob, int64, error)
}

type repository struct {
	db *gorm.DB
}

func NewRepository(db *gorm.DB) Repository {
	return &repository{db: db}
}

func (r *repository) Enqueue(ctx context.Context, jobType JobType, payload any) (*BackgroundJob, error) {
	raw, err := json.Marshal(payload)
	if err != nil {
		return nil, fmt.Errorf("marshal payload: %w", err)
	}

	job := &BackgroundJob{
		Type:    jobType,
		Status:  JobStatusQueued,
		Payload: datatypes.JSON(raw),
	}

	if err := r.db.WithContext(ctx).Create(job).Error; err != nil {
		return nil, fmt.Errorf("enqueue job: %w", err)
	}

	return job, nil
}

func (r *repository) PollNext(ctx context.Context, jobType JobType) (*BackgroundJob, error) {
	var job BackgroundJob

	err := r.db.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		result := tx.
			Clauses(clause.Locking{Strength: "UPDATE", Options: "SKIP LOCKED"}).
			Where(
				"type = ? AND status = ? AND (run_after IS NULL OR run_after <= ?)",
				jobType, JobStatusQueued, time.Now(),
			).
			Order("created_at ASC").
			First(&job)

		if result.Error != nil {
			return result.Error
		}

		now := time.Now()
		return tx.Model(&job).Updates(map[string]any{
			"status":     JobStatusProcessing,
			"started_at": &now,
		}).Error
	})

	if err != nil {
		return nil, err
	}

	return &job, nil
}

func (r *repository) MarkProcessing(ctx context.Context, id uint) error {
	now := time.Now()
	return r.db.WithContext(ctx).
		Model(&BackgroundJob{}).
		Where("id = ?", id).
		Updates(map[string]any{
			"status":     JobStatusProcessing,
			"started_at": &now,
		}).Error
}

func (r *repository) MarkDone(ctx context.Context, id uint) error {
	now := time.Now()
	return r.db.WithContext(ctx).
		Model(&BackgroundJob{}).
		Where("id = ?", id).
		Updates(map[string]any{
			"status":      JobStatusDone,
			"finished_at": &now,
			"error_msg":   "",
		}).Error
}

func (r *repository) MarkFailed(ctx context.Context, id uint, errMsg string) (bool, error) {
	job, err := r.GetByID(ctx, id)
	if err != nil {
		return false, err
	}

	now := time.Now()
	newRetryCount := job.RetryCount + 1
	willRetry := newRetryCount < job.MaxRetry

	updates := map[string]any{
		"retry_count": newRetryCount,
		"error_msg":   errMsg,
		"finished_at": &now,
	}

	if willRetry {

		backoff := time.Duration(1<<uint(newRetryCount)) * time.Minute
		runAfter := time.Now().Add(backoff)
		updates["status"] = JobStatusQueued
		updates["run_after"] = &runAfter
		updates["started_at"] = nil
		updates["finished_at"] = nil
	} else {
		updates["status"] = JobStatusFailed
	}

	return willRetry, r.db.WithContext(ctx).
		Model(&BackgroundJob{}).
		Where("id = ?", id).
		Updates(updates).Error
}

func (r *repository) MarkPendingManual(ctx context.Context, id uint) error {
	return r.db.WithContext(ctx).
		Model(&BackgroundJob{}).
		Where("id = ?", id).
		Update("status", JobStatusPendingManual).Error
}

func (r *repository) FlagStaleJobs(ctx context.Context, jobType JobType, olderThan time.Duration) ([]BackgroundJob, error) {
	threshold := time.Now().Add(-olderThan)

	var jobs []BackgroundJob
	err := r.db.WithContext(ctx).
		Where("type = ? AND status = ? AND created_at <= ?", jobType, JobStatusQueued, threshold).
		Find(&jobs).Error
	if err != nil {
		return nil, err
	}

	if len(jobs) == 0 {
		return nil, nil
	}

	ids := make([]uint, len(jobs))
	for i, j := range jobs {
		ids[i] = j.ID
	}

	if err := r.db.WithContext(ctx).
		Model(&BackgroundJob{}).
		Where("id IN ?", ids).
		Update("status", JobStatusPendingManual).Error; err != nil {
		return nil, err
	}

	return jobs, nil
}

func (r *repository) GetByID(ctx context.Context, id uint) (*BackgroundJob, error) {
	var job BackgroundJob
	if err := r.db.WithContext(ctx).First(&job, id).Error; err != nil {
		return nil, err
	}
	return &job, nil
}

func (r *repository) ListByStatus(ctx context.Context, jobType JobType, status JobStatus, page, pageSize int) ([]BackgroundJob, int64, error) {
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	q := r.db.WithContext(ctx).Model(&BackgroundJob{}).Where("type = ? AND status = ?", jobType, status)

	var total int64
	q.Count(&total)

	var jobs []BackgroundJob
	err := q.Order("created_at ASC").
		Limit(pageSize).
		Offset((page - 1) * pageSize).
		Find(&jobs).Error

	return jobs, total, err
}
