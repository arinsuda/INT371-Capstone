package chat

import "time"

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
	BookingID uint        `json:"booking_id"`
	Type      MessageType `json:"type" validate:"required,oneof=TEXT IMAGE"`
	Content   string      `form:"content" json:"content"`
}

type ReadEventPayload struct {
	BookingID uint `json:"booking_id"`
}
