package chat

import (
	"errors"
	"time"
)

type ChatRoomResponse struct {
	BookingID       uint        `json:"booking_id"`
	BookingNumber   string      `json:"booking_number"`
	BookingStatus   string      `json:"booking_status"`
	OtherPersonID   uint        `json:"other_person_id"`
	OtherPersonName string      `json:"other_person_name"`
	OtherPersonImg  string      `json:"other_person_img"`
	LastMessage     string      `json:"last_message"`
	LastMsgType     MessageType `json:"last_msg_type"`
	LastMsgTime     time.Time   `json:"last_msg_time"`
	UnreadCount     int         `json:"unread_count"`
}

type SendMessageReq struct {
	BookingID uint        `json:"booking_id" validate:"required,min=1"`
	Type      MessageType `json:"type" validate:"required,oneof=TEXT IMAGE"`
	Content   string      `form:"content" json:"content" validate:"required_if=Type TEXT"`
}

func (req *SendMessageReq) Validate() error {
	if req.BookingID == 0 {
		return errors.New("booking_id is required")
	}

	if !req.Type.IsValid() {
		return errors.New("type must be TEXT or IMAGE")
	}

	if req.Type == MsgTypeText && req.Content == "" {
		return errors.New("content is required for TEXT messages")
	}

	return nil
}

type ChatMessageResponse struct {
	ID         uint        `json:"id"`
	BookingID  uint        `json:"booking_id"`
	SenderID   uint        `json:"sender_id"`
	SenderRole string      `json:"sender_role"`
	Type       MessageType `json:"type"`
	Content    string      `json:"content"`
	IsRead     bool        `json:"is_read"`
	CreatedAt  time.Time   `json:"created_at"`
}

func (r *ChatMessageResponse) FromModel(msg *ChatMessage) {
	r.ID = msg.ID
	r.BookingID = msg.BookingID
	r.SenderID = msg.SenderID
	r.SenderRole = msg.SenderRole
	r.Type = msg.Type
	r.Content = msg.Content
	r.IsRead = msg.IsRead
	r.CreatedAt = msg.CreatedAt
}

type MarkAsReadReq struct {
	MessageIDs []uint `json:"message_ids" validate:"required,min=1"`
}

func (req *MarkAsReadReq) Validate() error {
	if len(req.MessageIDs) == 0 {
		return errors.New("message_ids cannot be empty")
	}
	return nil
}

type RoomReadEventPayload struct {
	BookingID  uint      `json:"booking_id"`
	ReaderRole string    `json:"reader_role"`
	ReadAt     time.Time `json:"read_at"`
}

type MessageReadEventPayload struct {
	BookingID  uint      `json:"booking_id"`
	MessageIDs []uint    `json:"message_ids"`
	ReadAt     time.Time `json:"read_at"`
}

type GetHistoryQuery struct {
	Limit  int `query:"limit" validate:"min=1,max=100"`
	Offset int `query:"offset" validate:"min=0"`
}

func (q *GetHistoryQuery) Validate() error {
	if q.Limit < 1 || q.Limit > 100 {
		return errors.New("limit must be between 1 and 100")
	}
	if q.Offset < 0 {
		return errors.New("offset must be non-negative")
	}
	return nil
}

func (q *GetHistoryQuery) SetDefaults() {
	if q.Limit == 0 {
		q.Limit = 50
	}
}
