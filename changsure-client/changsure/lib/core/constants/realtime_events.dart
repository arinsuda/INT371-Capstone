class RealtimeEvents {
  // Chat Events
  static const String newMessage = 'NEW_MESSAGE';
  static const String chatMessageNew = 'CHAT_MESSAGE_NEW';
  static const String roomRead = 'ROOM_READ';
  static const String chatRoomRead = 'CHAT_ROOM_READ';
  static const String messageRead = 'MESSAGE_READ';
  static const String chatMessageRead = 'CHAT_MESSAGE_READ';
  static const String chatListUpdated = 'CHAT_LIST_UPDATED';
  static const String chatRoomUpdated = 'CHAT_ROOM_UPDATED';
  static const String chatRoomLocked = 'CHAT_ROOM_LOCKED';

  // Booking Events
  static const String bookingCreated = 'BOOKING_CREATED';
  static const String bookingAccepted = 'BOOKING_ACCEPTED';
  static const String bookingRejected = 'BOOKING_REJECTED';
  static const String bookingCancelled = 'BOOKING_CANCELLED';
  static const String bookingCancelledByTech = 'BOOKING_CANCELLED_BY_TECH';
  static const String jobStarted = 'JOB_STARTED';
  static const String jobCompleted = 'JOB_COMPLETED';
  static const String bookingStatusChanged =
      'BOOKING_STATUS_CHANGED';

  // Notification Events
  static const String notificationNew = 'NOTIFICATION_NEW';

  // Connection Events
  static const String connected = 'CONNECTED';
  static const String error = 'ERROR';
}
