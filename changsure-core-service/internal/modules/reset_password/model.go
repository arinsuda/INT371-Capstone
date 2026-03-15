package resetpassword

import (
	"time"

	"github.com/google/uuid"
)

type UserRole string

const (
	RoleCustomer   UserRole = "customer"
	RoleTechnician UserRole = "technician"
)

type PasswordResetOTP struct {
	ID         uuid.UUID `gorm:"type:char(36);primaryKey"`
	UserID     uint      `gorm:"index;not null"`
	UserRole   UserRole  `gorm:"size:20;not null"`
	Email      string    `gorm:"size:100;index;not null"`
	TOTPSecret string    `gorm:"size:64;not null"`
	IsUsed     bool      `gorm:"default:false"`
	ExpiresAt  time.Time `gorm:"not null"`
	CreatedAt  time.Time
}

func (p *PasswordResetOTP) IsExpired() bool {
	return time.Now().After(p.ExpiresAt)
}

func (p *PasswordResetOTP) IsValid() bool {
	return !p.IsUsed && !p.IsExpired()
}

func Models() []interface{} {
	return []interface{}{&PasswordResetOTP{}}
}
