package customer

import (
	customer_addresses "changsure-core-service/internal/modules/customer_address"
	"time"

	"gorm.io/gorm"
)

type Customer struct {
	ID        uint   `gorm:"primaryKey;autoIncrement" json:"id"`
	FirstName string `gorm:"type:varchar(150);not null" json:"firstname"`
	LastName  string `gorm:"type:varchar(150);not null" json:"lastname"`

	Email        *string `gorm:"type:varchar(100);uniqueIndex" json:"email"`
	PasswordHash string  `gorm:"type:varchar(255);not null" json:"-"`

	Phone     *string        `gorm:"type:varchar(10)" json:"phone"`
	AvatarURL *string        `gorm:"type:varchar(500)" json:"avatar_url"`
	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index"`

	Addresses []customer_addresses.CustomerAddress `gorm:"foreignKey:CustomerID" json:"addresses,omitempty"`
}

func (Customer) TableName() string { return "customers" }

func Models() []interface{} {
	return []interface{}{
		&Customer{},
	}
}
