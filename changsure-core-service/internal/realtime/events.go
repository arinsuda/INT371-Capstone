package realtime

const (
	EventChatMessageNew  = "CHAT_MESSAGE_NEW"
	EventChatMessageRead = "CHAT_MESSAGE_READ"
	EventChatRoomRead    = "CHAT_ROOM_READ"
	EventChatRoomUpdated = "CHAT_ROOM_UPDATED"
	EventChatRoomLocked  = "CHAT_ROOM_LOCKED"
	EventChatListUpdated = "CHAT_LIST_UPDATED"

	EventBookingCreated         = "BOOKING_CREATED"
	EventBookingAccepted        = "BOOKING_ACCEPTED"
	EventBookingRejected        = "BOOKING_REJECTED"
	EventBookingCancelled       = "BOOKING_CANCELLED"
	EventBookingCancelledByTech = "BOOKING_CANCELLED_BY_TECH"
	EventJobStarted             = "JOB_STARTED"
	EventJobCompleted           = "JOB_COMPLETED"
	EventBookingStatusChanged   = "BOOKING_STATUS_CHANGED"

	EventNotificationNew = "NOTIFICATION_NEW"

	EventConnected = "CONNECTED"
	EventError     = "ERROR"
)
