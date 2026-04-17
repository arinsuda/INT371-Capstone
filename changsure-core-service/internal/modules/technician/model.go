package technician

import (
	"time"

	technicianaddress "changsure-core-service/internal/modules/technician_address"
	technicianbadge "changsure-core-service/internal/modules/technician_badge"
	tsvc "changsure-core-service/internal/modules/technician_service"
	technicianarea "changsure-core-service/internal/modules/technician_service_area"
)

type VerificationStatus string

const (
	StatusUnverified VerificationStatus = "UNVERIFIED" // ยังไม่เคยส่งบัตร (default)
	StatusPending    VerificationStatus = "PENDING"    // ส่งแล้ว รออยู่ใน queue
	StatusInReview   VerificationStatus = "IN_REVIEW"  // รอ admin ตรวจสอบ
	StatusApproved   VerificationStatus = "APPROVED"   // ผ่านการตรวจสอบ
	StatusRejected   VerificationStatus = "REJECTED"   // ไม่ผ่านการตรวจสอบ
)

type Technician struct {
	ID                 uint                                   `gorm:"primaryKey;autoIncrement" json:"id"`
	AvatarURL          *string                                `gorm:"type:varchar(500)" json:"avatar_url"`
	FirstName          string                                 `gorm:"type:varchar(150);not null" json:"firstname"`
	LastName           string                                 `gorm:"type:varchar(150);not null" json:"lastname"`
	Phone              *string                                `gorm:"type:varchar(10)" json:"phone"`
	Bio                *string                                `gorm:"type:text" json:"bio"`
	Email              *string                                `gorm:"type:varchar(100);uniqueIndex" json:"email"`
	PasswordHash       string                                 `gorm:"type:varchar(255);not null" json:"-"`
	IsAvailable        bool                                   `gorm:"default:true" json:"is_available"`
	VerificationStatus VerificationStatus                     `gorm:"type:varchar(20);index" json:"verification_status"`
	EmailVerifiedAt    *time.Time                             `gorm:"index" json:"email_verified_at,omitempty"`
	VerifiedAt         *time.Time                             `json:"verified_at,omitempty"`
	IDCardImageURL     *string                                `gorm:"type:varchar(500)" json:"-"`
	CreatedAt          time.Time                              `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt          time.Time                              `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt          *time.Time                             `gorm:"index" json:"-"`
	BannedAt           *time.Time                             `gorm:"index" json:"banned_at,omitempty"`
	RatingAvg          float64                                `gorm:"-" json:"rating_avg"`
	RatingCount        int64                                  `gorm:"-" json:"rating_count"`
	TotalJobs          int64                                  `gorm:"-" json:"total_jobs"`
	Addresses          []technicianaddress.TechnicianAddress  `gorm:"foreignKey:TechnicianID" json:"addresses,omitempty"`
	ServiceAreas       []technicianarea.TechnicianServiceArea `gorm:"foreignKey:TechnicianID" json:"service_areas,omitempty"`
	Badges             []technicianbadge.TechnicianBadge      `gorm:"foreignKey:TechnicianID" json:"badges,omitempty"`
	Services           []tsvc.TechnicianService               `gorm:"foreignKey:TechnicianID" json:"services,omitempty"`
}

func (Technician) TableName() string { return "technicians" }

func Models() []interface{} {
	return []interface{}{&Technician{}}
}
