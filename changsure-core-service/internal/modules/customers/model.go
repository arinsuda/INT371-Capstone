package customers

import (
	"time"
	customer_addresses "changsure-core-service/internal/modules/customer_addresses"
)

type Customer struct {
	ID         uint       `gorm:"primaryKey;autoIncrement" json:"id"`
	FirstName  string     `gorm:"type:varchar(150);not null" json:"firstname"`
	LastName   string     `gorm:"type:varchar(150);not null" json:"lastname"`
	Email      *string    `gorm:"type:varchar(100);uniqueIndex" json:"email"`
	Phone      *string    `gorm:"type:varchar(10)" json:"phone"`
	AvatarURL  *string    `gorm:"type:varchar(255)" json:"avatar_url"`
	CreatedAt  time.Time  `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt  time.Time  `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt  *time.Time `gorm:"index" json:"-"`

	Addresses []customer_addresses.CustomerAddress `gorm:"foreignKey:CustomerID" json:"addresses,omitempty"`
}

func (Customer) TableName() string { return "customers" }

func Models() []interface{} {
	return []interface{}{
		&Customer{},
	}
}