package customeraddress

import (
	addressshared "changsure-core-service/internal/modules/address_shared"
	"time"
)

type CustomerAddress struct {
	ID uint `gorm:"primaryKey;autoIncrement" json:"id"`

	addressshared.AddressFields

	CustomerID uint `gorm:"not null;index" json:"customer_id"`

	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

func Models() []interface{} {
	return []interface{}{
		&CustomerAddress{},
	}
}
