package backgroundjob

import (
	"time"

	"gorm.io/datatypes"
)

type JobType string
type JobStatus string

const (
	JobTypeOCRVerify JobType = "OCR_VERIFY"
	JobTypeEmail     JobType = "SEND_EMAIL"
)

const (
	JobStatusQueued        JobStatus = "QUEUED"
	JobStatusProcessing    JobStatus = "PROCESSING"
	JobStatusDone          JobStatus = "DONE"
	JobStatusFailed        JobStatus = "FAILED"
	JobStatusPendingManual JobStatus = "PENDING_MANUAL"
)

type BackgroundJob struct {
	ID         uint           `gorm:"primaryKey;autoIncrement"`
	Type       JobType        `gorm:"type:varchar(50);not null;index"`
	Status     JobStatus      `gorm:"type:varchar(30);not null;index;default:'QUEUED'"`
	Payload    datatypes.JSON `gorm:"type:json;not null"`
	RetryCount int            `gorm:"not null;default:0"`
	MaxRetry   int            `gorm:"not null;default:3"`
	ErrorMsg   string         `gorm:"type:text"`

	RunAfter   *time.Time `gorm:"index"`
	CreatedAt  time.Time  `gorm:"autoCreateTime;index"`
	StartedAt  *time.Time
	FinishedAt *time.Time
}

func (BackgroundJob) TableName() string { return "background_jobs" }

func Models() []interface{} {
	return []interface{}{&BackgroundJob{}}
}

type OCRVerifyPayload struct {
	TechnicianID uint   `json:"technician_id"`
	ImagePath    string `json:"image_path"`
	Filename     string `json:"filename"`
}

type EmailPayload struct {
	To       string         `json:"to"`
	Template string         `json:"template"`
	Data     map[string]any `json:"data"`
}
