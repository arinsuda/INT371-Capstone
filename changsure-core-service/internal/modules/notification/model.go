package notification

import (
	"database/sql/driver"
	"encoding/json"
	"errors"
	"time"

	"gorm.io/gorm"
)

type RecipientRole string

const (
	RoleCustomer   RecipientRole = "customer"
	RoleTechnician RecipientRole = "technician"
)

func (r RecipientRole) Valid() bool {
	return r == RoleCustomer || r == RoleTechnician
}

type JSONMap map[string]any

func (m JSONMap) Value() (driver.Value, error) {
	if m == nil {
		return []byte("{}"), nil
	}
	b, err := json.Marshal(m)
	if err != nil {
		return nil, err
	}
	return b, nil
}

func (m *JSONMap) Scan(value any) error {
	if value == nil {
		*m = JSONMap{}
		return nil
	}

	var bytes []byte
	switch v := value.(type) {
	case []byte:
		bytes = v
	case string:
		bytes = []byte(v)
	default:
		return errors.New("unsupported type for JSONMap")
	}

	if len(bytes) == 0 {
		*m = JSONMap{}
		return nil
	}

	var out map[string]any
	if err := json.Unmarshal(bytes, &out); err != nil {
		return err
	}
	*m = out
	return nil
}

type Notification struct {
	ID            uint          `gorm:"primaryKey" json:"id"`
	RecipientRole RecipientRole `gorm:"type:enum('customer','technician');not null;index:idx_recipient" json:"recipient_role"`
	RecipientID   uint          `gorm:"not null;index:idx_recipient" json:"recipient_id"`

	Type    string `gorm:"type:varchar(64);not null;index" json:"type"`
	Title   string `gorm:"type:varchar(255);not null" json:"title"`
	Message string `gorm:"type:text;not null" json:"message"`

	EntityType string `gorm:"type:varchar(32);index" json:"entity_type"`
	EntityID   uint   `gorm:"index" json:"entity_id"`

	Data JSONMap `gorm:"type:json" json:"data"`

	IsRead bool       `gorm:"not null;default:false;index:idx_unread" json:"is_read"`
	ReadAt *time.Time `json:"read_at"`

	CreatedAt time.Time      `gorm:"autoCreateTime" json:"created_at"`
	UpdatedAt time.Time      `gorm:"autoUpdateTime" json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index" json:"-"`
}

func (Notification) TableName() string {
	return "notifications"
}

func Models() []interface{} {
	return []interface{}{
		&Notification{},
	}
}
