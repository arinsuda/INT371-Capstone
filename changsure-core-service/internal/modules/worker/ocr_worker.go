package worker

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/redis/go-redis/v9"
	"gorm.io/gorm"

	"changsure-core-service/internal/modules/admin"
	backgroundjob "changsure-core-service/internal/modules/background_job"
	criminalcheck "changsure-core-service/internal/modules/criminal_check"
	"changsure-core-service/internal/modules/notification"
	ocrservice "changsure-core-service/internal/modules/ocr/service"
	"changsure-core-service/internal/modules/technician"
	"changsure-core-service/pkg/storage"
)

const (
	redisKeyOCRActive = "ocr:active_jobs"
)

type OCRWorkerConfig struct {
	MaxConcurrent   int
	PollInterval    time.Duration
	ManualThreshold time.Duration
	SemaphoreExpiry time.Duration
}

func DefaultOCRWorkerConfig() OCRWorkerConfig {
	return OCRWorkerConfig{
		MaxConcurrent:   2,
		PollInterval:    5 * time.Second,
		ManualThreshold: 30 * time.Minute,
		SemaphoreExpiry: 3 * time.Minute,
	}
}

type OCRWorkerDeps struct {
	JobRepo      backgroundjob.Repository
	OCRService   ocrservice.OCRService
	CriminalRepo criminalcheck.Repository
	TechRepo     technician.Repository
	NotiService  notification.Service
	Storage      storage.Storage
	Redis        *redis.Client
	Config       OCRWorkerConfig
	AdminRepo    admin.Repository
}

type OCRWorker struct {
	deps OCRWorkerDeps
}

func NewOCRWorker(deps OCRWorkerDeps) *OCRWorker {
	return &OCRWorker{deps: deps}
}

func (w *OCRWorker) Start(ctx context.Context) {
	cfg := w.deps.Config
	pollTicker := time.NewTicker(cfg.PollInterval)
	staleTicker := time.NewTicker(cfg.ManualThreshold / 2)
	defer pollTicker.Stop()
	defer staleTicker.Stop()

	log.Printf("🔧 OCR Worker started (maxConcurrent=%d, pollInterval=%s, manualThreshold=%s)",
		cfg.MaxConcurrent, cfg.PollInterval, cfg.ManualThreshold)

	for {
		select {
		case <-ctx.Done():
			log.Println("🔧 OCR Worker stopped")
			return
		case <-pollTicker.C:
			w.processNext(ctx)
		case <-staleTicker.C:
			w.flagStaleJobs(ctx)
		}
	}
}

func (w *OCRWorker) processNext(ctx context.Context) {
	if !w.acquireSemaphore(ctx) {
		return
	}

	job, err := w.deps.JobRepo.PollNext(ctx, backgroundjob.JobTypeOCRVerify)
	if err != nil {
		w.releaseSemaphore(ctx)
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("❌ OCR Worker: poll error: %v", err)
		}
		return
	}

	go func() {
		defer w.releaseSemaphore(ctx)
		w.executeJob(ctx, job)
	}()
}

func (w *OCRWorker) executeJob(ctx context.Context, job *backgroundjob.BackgroundJob) {
	log.Printf("🔍 OCR Worker: processing job_id=%d", job.ID)

	var payload backgroundjob.OCRVerifyPayload
	if err := json.Unmarshal(job.Payload, &payload); err != nil {
		w.failJob(ctx, job, fmt.Sprintf("decode payload: %v", err))
		return
	}

	imageBytes, err := w.deps.Storage.Download(ctx, payload.ImagePath)
	if err != nil {
		w.failJob(ctx, job, fmt.Sprintf("download image: %v", err))
		return
	}

	ocrResult, err := w.deps.OCRService.ProcessOCR(imageBytes, payload.Filename)
	if err != nil {
		w.failJob(ctx, job, fmt.Sprintf("ocr failed: %v", err))
		return
	}

	result, err := criminalcheck.ProcessVerification(
		ctx,
		payload.TechnicianID,
		ocrResult.Items,
		w.deps.CriminalRepo,
		w.deps.TechRepo,
	)
	if err != nil {
		w.failJob(ctx, job, fmt.Sprintf("process result: %v", err))
		return
	}

	switch result.Status {
	case criminalcheck.StatusPassed,
		criminalcheck.StatusFailed,
		criminalcheck.StatusOCRFailed,
		criminalcheck.StatusNameNotExtracted:
		w.notifyTechnician(ctx, payload.TechnicianID, result.Status, result.Note)

	}

	if err := w.deps.JobRepo.MarkDone(ctx, job.ID); err != nil {
		log.Printf("⚠️ OCR Worker: mark done failed job_id=%d: %v", job.ID, err)
	}

	log.Printf("✅ OCR Worker: job_id=%d done (status=%s)", job.ID, result.Status)
}

func (w *OCRWorker) flagStaleJobs(ctx context.Context) {
	staleJobs, err := w.deps.JobRepo.FlagStaleJobs(
		ctx,
		backgroundjob.JobTypeOCRVerify,
		w.deps.Config.ManualThreshold,
	)
	if err != nil {
		log.Printf("❌ OCR Worker: flag stale error: %v", err)
		return
	}

	for _, job := range staleJobs {
		log.Printf("⚠️ OCR Worker: job_id=%d flagged as PENDING_MANUAL", job.ID)

		var payload backgroundjob.OCRVerifyPayload
		if err := json.Unmarshal(job.Payload, &payload); err != nil {
			continue
		}
		w.notifyAdminManualReview(ctx, job.ID, payload.TechnicianID)
	}
}

func (w *OCRWorker) acquireSemaphore(ctx context.Context) bool {
	cfg := w.deps.Config

	val, err := w.deps.Redis.Incr(ctx, redisKeyOCRActive).Result()
	if err != nil {
		log.Printf("⚠️ OCR Worker: redis incr error: %v", err)
		return true
	}

	w.deps.Redis.Expire(ctx, redisKeyOCRActive, cfg.SemaphoreExpiry)

	if int(val) > cfg.MaxConcurrent {
		w.deps.Redis.Decr(ctx, redisKeyOCRActive)
		return false
	}

	return true
}

func (w *OCRWorker) releaseSemaphore(ctx context.Context) {
	val, err := w.deps.Redis.Decr(ctx, redisKeyOCRActive).Result()
	if err != nil {
		log.Printf("⚠️ OCR Worker: redis decr error: %v", err)
		return
	}
	if val < 0 {
		w.deps.Redis.Set(ctx, redisKeyOCRActive, 0, w.deps.Config.SemaphoreExpiry)
	}
}

func (w *OCRWorker) failJob(ctx context.Context, job *backgroundjob.BackgroundJob, errMsg string) {
	log.Printf("❌ OCR Worker: job_id=%d failed: %s", job.ID, errMsg)

	willRetry, err := w.deps.JobRepo.MarkFailed(ctx, job.ID, errMsg)
	if err != nil {
		log.Printf("⚠️ OCR Worker: mark failed error job_id=%d: %v", job.ID, err)
	}

	if willRetry {
		log.Printf("🔄 OCR Worker: job_id=%d will retry (count=%d)", job.ID, job.RetryCount+1)
	} else {
		log.Printf("💀 OCR Worker: job_id=%d exhausted retries", job.ID)

		var payload backgroundjob.OCRVerifyPayload
		if err := json.Unmarshal(job.Payload, &payload); err == nil {
			w.notifyTechnician(ctx, payload.TechnicianID, criminalcheck.StatusOCRFailed,
				"ระบบไม่สามารถตรวจสอบรูปภาพได้ กรุณาลองใหม่หรือติดต่อเจ้าหน้าที่")
		}
	}
}

func (w *OCRWorker) notifyTechnician(ctx context.Context, technicianID uint, status criminalcheck.CheckStatus, note string) {
	if w.deps.NotiService == nil {
		return
	}

	var title, message, notiType string
	switch status {
	case criminalcheck.StatusPassed:
		notiType = "IDENTITY_VERIFIED"
		title = "ยืนยันตัวตนสำเร็จ ✅"
		message = "บัตรประชาชนของคุณผ่านการตรวจสอบแล้ว คุณสามารถรับงานได้เลย"
	case criminalcheck.StatusOCRFailed, criminalcheck.StatusNameNotExtracted:
		notiType = "IDENTITY_OCR_FAILED"
		title = "ไม่สามารถอ่านบัตรประชาชนได้ ⚠️"
		message = "กรุณาถ่ายรูปบัตรประชาชนให้ชัดเจนและลองใหม่อีกครั้ง"
	default:
		return
	}

	_, _ = w.deps.NotiService.Create(ctx, notification.CreateNotificationInput{
		RecipientRole: notification.RoleTechnician,
		RecipientID:   technicianID,
		Type:          notiType,
		Title:         title,
		Message:       message,
		EntityType:    "technician",
		EntityID:      technicianID,
		Data:          map[string]any{"status": string(status), "note": note},
	})
}

func (w *OCRWorker) notifyAdminManualReview(ctx context.Context, jobID, technicianID uint) {
	log.Printf("📋 Admin manual review needed: job_id=%d technician_id=%d", jobID, technicianID)

	if w.deps.NotiService == nil || w.deps.AdminRepo == nil {
		return
	}

	admins, err := w.deps.AdminRepo.FindAll(ctx)
	if err != nil {
		log.Printf("⚠️ OCR Worker: failed to fetch admins for notification: %v", err)
		return
	}

	for _, a := range admins {
		_, _ = w.deps.NotiService.Create(ctx, notification.CreateNotificationInput{
			RecipientRole: notification.RoleAdmin,
			RecipientID:   a.ID,
			Type:          "MANUAL_REVIEW_REQUIRED",
			Title:         "มีคำขอยืนยันตัวตนรอการตรวจสอบ 📋",
			Message:       fmt.Sprintf("job_id=%d technician_id=%d รอการอนุมัติจาก admin", jobID, technicianID),
			EntityType:    "background_job",
			EntityID:      jobID,
			Data: map[string]any{
				"job_id":        jobID,
				"technician_id": technicianID,
			},
		})
	}
}
