enum MessageType { TEXT, IMAGE }

class ChatRoom {
  final int bookingId;
  final String bookingNumber;
  final String bookingStatus;
  final int otherPersonId;
  final String otherPersonName;
  final String otherPersonImg;
  final String lastMessage;
  final String lastMsgType;
  final DateTime lastMsgTime;
  final int unreadCount;

  ChatRoom({
    required this.bookingId,
    required this.bookingNumber,
    required this.bookingStatus,
    required this.otherPersonId,
    required this.otherPersonName,
    required this.otherPersonImg,
    required this.lastMessage,
    required this.lastMsgType,
    required this.lastMsgTime,
    required this.unreadCount,
  });

  ChatRoom copyWith({
    int? unreadCount,
    String? lastMessage,
    String? lastMsgType,
    DateTime? lastMsgTime,
  }) {
    return ChatRoom(
      bookingId: bookingId,
      bookingNumber: bookingNumber,
      bookingStatus: bookingStatus,
      otherPersonId: otherPersonId,
      otherPersonName: otherPersonName,
      otherPersonImg: otherPersonImg,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMsgType: lastMsgType ?? this.lastMsgType,
      lastMsgTime: lastMsgTime ?? this.lastMsgTime,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      bookingId: json['booking_id'] ?? 0,
      bookingNumber: json['booking_number'] ?? "",
      bookingStatus: json['booking_status'] ?? "",
      otherPersonId: json['other_person_id'] ?? 0,
      otherPersonName: json['other_person_name'] ?? "Unknown",
      otherPersonImg: json['other_person_img'] ?? "",
      lastMessage: json['last_message'] ?? "",
      lastMsgType: json['last_msg_type'] ?? "TEXT",
      lastMsgTime: json['last_msg_time'] != null
          ? DateTime.parse(json['last_msg_time'])
          : DateTime.now(),
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ChatMessage {
  final int id;
  final int bookingId;
  final int senderId;
  final String senderRole;
  final MessageType type;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  ChatMessage copyWith({bool? isRead}) {
    return ChatMessage(
      id: id,
      bookingId: bookingId,
      senderId: senderId,
      senderRole: senderRole,
      type: type,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      senderRole: json['sender_role'] ?? "",
      type: (json['type'] == "IMAGE") ? MessageType.IMAGE : MessageType.TEXT,
      content: json['content'] ?? "",
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class SendMessageRequest {
  final int bookingId;
  final String content;
  final String type;

  SendMessageRequest({
    required this.bookingId,
    required this.content,
    this.type = "TEXT",
  });

  Map<String, dynamic> toJson() => {
    "booking_id": bookingId,
    "content": content,
    "type": type,
  };
}
