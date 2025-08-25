package verification

import "time"

type TechnicianVerification struct {
	ID              uint64     `gorm:"primaryKey;autoIncrement"`
	TechnicianID    uint64     `gorm:"column:technician_id;not null"`
	DocType         string     `gorm:"column:doc_type;type:enum('id_card','certificate','license','portfolio','insurance');not null"`
	DocURL          string     `gorm:"column:doc_url;size:500;not null"`
	DocNumber       *string    `gorm:"column:doc_number;size:100"`
	IssuedBy        *string    `gorm:"column:issued_by;size:200"`
	ExpiresAt       *time.Time `gorm:"column:expires_at"`
	VerifyStatus    string     `gorm:"column:verify_status;type:enum('pending','approved','rejected','expired');default:'pending'"`
	VerifiedBy      *uint64    `gorm:"column:verified_by"`
	VerifiedAt      *time.Time `gorm:"column:verified_at"`
	RejectionReason *string    `gorm:"column:rejection_reason;size:500"`
	Notes           *string    `gorm:"column:notes;type:text"`
	CreatedAt       time.Time  `gorm:"column:created_at;autoCreateTime"`
	UpdatedAt       time.Time  `gorm:"column:updated_at;autoUpdateTime"`
}

func (TechnicianVerification) TableName() string { return "technician_verifications" }
