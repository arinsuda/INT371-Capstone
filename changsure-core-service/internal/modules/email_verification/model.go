package emailverification

import "time"

type EmailOTP struct {
	ID           uint       `gorm:"primaryKey;autoIncrement"`
	Email        string     `gorm:"type:varchar(100);not null;index"`
	Role         string     `gorm:"type:varchar(20);not null"`
	UserID       uint       `gorm:"not null;index"`
	OTP          string     `gorm:"type:varchar(6);not null"`
	ExpiresAt    time.Time  `gorm:"not null"`
	AttemptCount int        `gorm:"default:0"`
	ResendAt     *time.Time 
	VerifiedAt   *time.Time `gorm:"index"`
	CreatedAt    time.Time  `gorm:"autoCreateTime"`
}

func (EmailOTP) TableName() string { return "email_otps" }

func Models() []interface{} {
	return []interface{}{&EmailOTP{}}
}