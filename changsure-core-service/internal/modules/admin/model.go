package admin

import "time"

type Admin struct {
	ID           uint       `gorm:"primaryKey;autoIncrement"`
	Avatar       *string    `gorm:"type:text"`
	FirstName    string     `gorm:"type:varchar(150);not null"`
	LastName     string     `gorm:"type:varchar(150);not null"`
	Email        string     `gorm:"type:varchar(100);uniqueIndex;not null"`
	PasswordHash string     `gorm:"type:varchar(255);not null" json:"-"`
	CreatedAt    time.Time  `gorm:"autoCreateTime"`
	UpdatedAt    time.Time  `gorm:"autoUpdateTime"`
	DeletedAt    *time.Time `gorm:"index"`
}

func (Admin) TableName() string { return "admins" }

func Models() []interface{} {
	return []interface{}{&Admin{}}
}
