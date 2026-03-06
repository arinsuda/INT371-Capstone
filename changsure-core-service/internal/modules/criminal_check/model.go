package criminalcheck

import "time"

type CheckStatus string

const (
	StatusPassed           CheckStatus = "PASSED"
	StatusFailed           CheckStatus = "FAILED"
	StatusPending          CheckStatus = "PENDING"
	StatusNotFound         CheckStatus = "NOT_FOUND"
	StatusOCRFailed        CheckStatus = "OCR_FAILED"
	StatusNameNotExtracted CheckStatus = "NAME_NOT_EXTRACTED"
)

type VerificationLog struct {
	ID           uint        `gorm:"primaryKey;autoIncrement"`
	TechnicianID uint        `gorm:"index;not null"`
	NationalID   string      `gorm:"size:13;not null"`
	Status       CheckStatus `gorm:"size:20;not null"`
	Note         string      `gorm:"type:text"`
	RawOCRText   string      `gorm:"type:text"`
	CreatedAt    time.Time   `gorm:"autoCreateTime"`
}

type AdminOverrideLog struct {
	ID            uint      `gorm:"primaryKey;autoIncrement"`
	AdminID       uint      `gorm:"index;not null"`
	TechnicianID  uint      `gorm:"index;not null"`
	TargetType    string    `gorm:"size:30;not null"`
	TargetID      uint      `gorm:"index"`
	PreviousValue string    `gorm:"size:50"`
	NewValue      string    `gorm:"size:50"`
	Reason        string    `gorm:"type:text;not null"`
	CreatedAt     time.Time `gorm:"autoCreateTime"`
}

type MockCriminalRecord struct {
	ID         uint        `gorm:"primaryKey;autoIncrement"`
	NationalID string      `gorm:"size:13;uniqueIndex;not null"`
	FullName   string      `gorm:"size:200;not null"`
	Status     CheckStatus `gorm:"size:20;not null"`
	Note       string      `gorm:"type:text"`
	CreatedAt  time.Time   `gorm:"autoCreateTime"`
	UpdatedAt  time.Time   `gorm:"autoUpdateTime"`
}

func (MockCriminalRecord) TableName() string { return "mock_criminal_records" }

func (VerificationLog) TableName() string { return "verification_logs" }

func (AdminOverrideLog) TableName() string { return "admin_override_logs" }

func Models() []interface{} {
	return []interface{}{
		&MockCriminalRecord{},
		&VerificationLog{},
		&AdminOverrideLog{},
	}
}
