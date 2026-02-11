package chat

import (
	"time"
)

type MessageType string

const (
	MsgTypeText  MessageType = "TEXT"
	MsgTypeImage MessageType = "IMAGE"
)

func (mt MessageType) IsValid() bool {
	switch mt {
	case MsgTypeText, MsgTypeImage:
		return true
	default:
		return false
	}
}

type ChatMessage struct {
	ID         uint        `gorm:"primaryKey;autoIncrement" json:"id"`
	BookingID  uint        `gorm:"index:idx_booking_created;not null" json:"booking_id"`
	SenderID   uint        `gorm:"index;not null" json:"sender_id"`
	SenderRole string      `gorm:"type:varchar(20);not null;index" json:"sender_role"`
	Type       MessageType `gorm:"type:varchar(10);not null;default:'TEXT'" json:"type"`
	Content    string      `gorm:"type:text;not null" json:"content"`
	IsRead     bool        `gorm:"default:false;index" json:"is_read"`
	CreatedAt  time.Time   `gorm:"index:idx_booking_created;not null" json:"created_at"`
	UpdatedAt  time.Time   `json:"updated_at"`
}

func (ChatMessage) TableName() string {
	return "chat_messages"
}

func (m *ChatMessage) BeforeCreate() error {
	if m.CreatedAt.IsZero() {
		m.CreatedAt = time.Now()
	}
	return nil
}

func Models() []interface{} {
	return []interface{}{
		&ChatMessage{},
	}
}
