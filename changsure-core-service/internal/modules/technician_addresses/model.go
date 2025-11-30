package technician_addresses

import (
	"changsure-core-service/internal/modules/address_shared"
	"time"
)

type TechnicianAddress struct {
	ID uint `gorm:"primaryKey;autoIncrement" json:"id"`

	address_shared.AddressFields

	TechnicianID uint `gorm:"index;not null" json:"technician_id"`

	CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`
}

func (TechnicianAddress) TableName() string { return "technician_addresses" }

func Models() []interface{} {
	return []interface{}{
		&TechnicianAddress{},
	}
}
