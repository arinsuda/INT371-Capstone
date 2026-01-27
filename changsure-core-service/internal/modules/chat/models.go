package chat

import (
	"time"
)

type MessageType string

const (
	MsgTypeText  MessageType = "TEXT"
	MsgTypeImage MessageType = "IMAGE"
)

type ChatMessage struct {
	ID         uint        `gorm:"primaryKey;autoIncrement" json:"id"`
	BookingID  uint        `gorm:"index;not null" json:"booking_id"`
	SenderID   uint        `gorm:"not null" json:"sender_id"`
	SenderRole string      `gorm:"type:varchar(20);not null" json:"sender_role"`
	Type       MessageType `gorm:"type:varchar(10);not null" json:"type"`
	Content    string      `gorm:"type:text;not null" json:"content"`
	IsRead     bool        `gorm:"default:false" json:"is_read"`
	CreatedAt  time.Time   `json:"created_at"`
}

func (ChatMessage) TableName() string {
	return "chat_messages"
}

func Models() []interface{} {
	return []interface{}{
		&ChatMessage{},
	}
}
