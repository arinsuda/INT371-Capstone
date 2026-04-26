package criminalcheck

import "time"

type CheckStatus string

const (
	StatusPassed       CheckStatus = "PASSED"        // ผ่านทุก check
	StatusRejected     CheckStatus = "REJECTED"      // ติด blacklist
	StatusPending      CheckStatus = "PENDING"       // รอ admin (ชื่อไม่ตรง ฯลฯ)
	StatusOCRFailed    CheckStatus = "OCR_FAILED"    // OCR อ่านบัตรไม่ได้เลย
	StatusNameMismatch CheckStatus = "NAME_MISMATCH" // อ่านได้ แต่ชื่อไม่ตรง
)

type VerificationLog struct {
	ID           uint        `gorm:"primaryKey;autoIncrement"`
	TechnicianID uint        `gorm:"index;not null;constraint:OnDelete:CASCADE"`
	NationalID   string      `gorm:"size:13;not null"`
	Status       CheckStatus `gorm:"size:20;not null"`
	Note         string      `gorm:"type:text"`
	RawOCRText   string      `gorm:"type:text"`
	CreatedAt    time.Time   `gorm:"autoCreateTime"`
}

type AdminOverrideLog struct {
	ID            uint      `gorm:"primaryKey;autoIncrement"`
	AdminID       uint      `gorm:"index;not null;constraint:OnDelete:RESTRICT"`
	TechnicianID  uint      `gorm:"index;not null;constraint:OnDelete:CASCADE"`
	TargetType    string    `gorm:"size:30;not null"`
	TargetID      uint      `gorm:"index"`
	PreviousValue string    `gorm:"size:50"`
	NewValue      string    `gorm:"size:50"`
	Reason        string    `gorm:"type:text;not null"`
	CreatedAt     time.Time `gorm:"autoCreateTime"`
}

type CriminalBlacklist struct {
	ID         uint      `gorm:"primaryKey;autoIncrement"`
	NationalID string    `gorm:"size:13;uniqueIndex;not null"`
	FullName   string    `gorm:"size:200;not null"`
	Note       string    `gorm:"type:text"`
	CreatedAt  time.Time `gorm:"autoCreateTime"`
	UpdatedAt  time.Time `gorm:"autoUpdateTime"`
}

func (CriminalBlacklist) TableName() string { return "criminal_blacklists" }

func (VerificationLog) TableName() string { return "verification_logs" }

func (AdminOverrideLog) TableName() string { return "admin_override_logs" }

func Models() []interface{} {
	return []interface{}{
		&CriminalBlacklist{},
		&VerificationLog{},
		&AdminOverrideLog{},
	}
}
