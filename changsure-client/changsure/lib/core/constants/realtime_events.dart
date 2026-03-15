abstract class RealtimeEvents {
  static const chatMessageNew = 'CHAT_MESSAGE_NEW';
  static const chatMessageRead = 'CHAT_MESSAGE_READ';
  static const chatRoomRead = 'CHAT_ROOM_READ';
  static const chatRoomUpdated = 'CHAT_ROOM_UPDATED';
  static const chatRoomLocked = 'CHAT_ROOM_LOCKED';
  static const chatListUpdated = 'CHAT_LIST_UPDATED';

  static const bookingCreated = 'BOOKING_CREATED';
  static const bookingAccepted = 'BOOKING_ACCEPTED';
  static const bookingRejected = 'BOOKING_REJECTED';
  static const bookingCancelled = 'BOOKING_CANCELLED';
  static const bookingCancelledByTech = 'BOOKING_CANCELLED_BY_TECH';
  static const jobStarted = 'JOB_STARTED';
  static const jobCompleted = 'JOB_COMPLETED';
  static const bookingStatusChanged = 'BOOKING_STATUS_CHANGED';

  static const notificationNew = 'NOTIFICATION_NEW';

  static const connected = 'CONNECTED';
  static const error = 'ERROR';

  static const paymentSuccess = 'PAYMENT_SUCCESS';
  static const paymentFailed = 'PAYMENT_FAILED';
  
  @Deprecated('ใช้ chatMessageNew แทน')
  static const newMessage = chatMessageNew;

  @Deprecated('ใช้ chatRoomRead แทน')
  static const roomRead = chatRoomRead;

  @Deprecated('ใช้ chatMessageRead แทน')
  static const messageRead = chatMessageRead;
}
