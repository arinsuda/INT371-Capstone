import 'package:freezed_annotation/freezed_annotation.dart';

enum ChatCategory { all, inProgress, completed }

enum MessageType {
  @JsonValue('TEXT')
  text('TEXT'),

  @JsonValue('IMAGE')
  image('IMAGE');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => MessageType.text,
    );
  }
}

enum BookingStatus {
  pending('PENDING'),
  confirmed('CONFIRMED'),
  accepted('ACCEPTED'),
  inProgress('IN_PROGRESS'),
  waitingPayment('WAITING_PAYMENT'),
  completed('COMPLETED'),
  cancelled('CANCELLED');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value.toUpperCase(),
      orElse: () => BookingStatus.pending,
    );
  }

  bool get isChatAllowed {
    return this == BookingStatus.accepted ||
        this == BookingStatus.inProgress ||
        this == BookingStatus.waitingPayment;
  }
}

class ChatRoom {
  final int bookingId;
  final String bookingNumber;
  final BookingStatus bookingStatus;
  final String serviceCategory;
  final int otherPersonId;
  final String otherPersonName;
  final String otherPersonImg;
  final String lastMessage;
  final MessageType lastMsgType;
  final DateTime lastMsgTime;
  final String lastSender;
  final int unreadCount;
  final bool canSendMessage;

  const ChatRoom({
    required this.bookingId,
    required this.bookingNumber,
    required this.bookingStatus,
    required this.serviceCategory,
    required this.otherPersonId,
    required this.otherPersonName,
    required this.otherPersonImg,
    required this.lastMessage,
    required this.lastMsgType,
    required this.lastMsgTime,
    required this.lastSender,
    required this.unreadCount,
    required this.canSendMessage,
  });

  ChatRoom copyWith({
    int? bookingId,
    String? bookingNumber,
    BookingStatus? bookingStatus,
    String? serviceCategory,
    int? otherPersonId,
    String? otherPersonName,
    String? otherPersonImg,
    String? lastMessage,
    MessageType? lastMsgType,
    DateTime? lastMsgTime,
    String? lastSender,
    int? unreadCount,
    bool? canSendMessage,
  }) {
    return ChatRoom(
      bookingId: bookingId ?? this.bookingId,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      otherPersonId: otherPersonId ?? this.otherPersonId,
      otherPersonName: otherPersonName ?? this.otherPersonName,
      otherPersonImg: otherPersonImg ?? this.otherPersonImg,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMsgType: lastMsgType ?? this.lastMsgType,
      lastMsgTime: lastMsgTime ?? this.lastMsgTime,
      lastSender: lastSender ?? this.lastSender,
      unreadCount: unreadCount ?? this.unreadCount,
      canSendMessage: canSendMessage ?? this.canSendMessage,
    );
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    try {
      return ChatRoom(
        bookingId: _parseInt(json['booking_id']) ?? 0,
        bookingNumber: _parseString(json['booking_number']) ?? '',
        bookingStatus: BookingStatus.fromString(
          _parseString(json['booking_status']) ?? 'PENDING',
        ),
        serviceCategory: _parseString(json['service_category']) ?? '',
        otherPersonId: _parseInt(json['other_person_id']) ?? 0,
        otherPersonName: _parseString(json['other_person_name']) ?? 'Unknown',
        otherPersonImg: _parseString(json['other_person_img']) ?? '',
        lastMessage: _parseString(json['last_message']) ?? '',
        lastMsgType: MessageType.fromString(
          _parseString(json['last_msg_type']) ?? 'TEXT',
        ),

        lastMsgTime: _parseDateTime(json['last_msg_time']) ?? DateTime.now(),
        lastSender: _parseString(json['last_sender']) ?? '',
        unreadCount: _parseInt(json['unread_count']) ?? 0,
        canSendMessage: _parseBool(json['can_send_message']) ?? true,
      );
    } catch (error) {
      throw FormatException('Failed to parse ChatRoom: $error');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'booking_number': bookingNumber,
      'booking_status': bookingStatus.value,
      'service_category': serviceCategory,
      'other_person_id': otherPersonId,
      'other_person_name': otherPersonName,
      'other_person_img': otherPersonImg,
      'last_message': lastMessage,
      'last_msg_type': lastMsgType.value,
      'last_msg_time': lastMsgTime.toIso8601String(),
      'last_sender': lastSender,
      'unread_count': unreadCount,
      'can_send_message': canSendMessage,
    };
  }

  bool get hasUnread => unreadCount > 0;

  bool get isChatAllowed => bookingStatus.isChatAllowed && canSendMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoom &&
          runtimeType == other.runtimeType &&
          bookingId == other.bookingId;

  @override
  int get hashCode => bookingId.hashCode;

  @override
  String toString() {
    return 'ChatRoom(bookingId: $bookingId, bookingNumber: $bookingNumber, '
        'unreadCount: $unreadCount)';
  }
}

class ChatMessage {
  final int id;
  final int bookingId;
  final String bookingNumber;
  final String serviceCategory;

  final int senderId;
  final String senderRole;
  final String senderName;
  final String senderAvatar;

  final MessageType type;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    required this.serviceCategory,
    required this.senderId,
    required this.senderRole,
    required this.senderName,
    required this.senderAvatar,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  ChatMessage copyWith({
    int? id,
    int? bookingId,
    String? bookingNumber,
    String? serviceCategory,
    int? senderId,
    String? senderRole,
    String? senderName,
    String? senderAvatar,
    MessageType? type,
    String? content,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      final booking = json['booking'] as Map<String, dynamic>? ?? {};

      final sender = json['sender'] as Map<String, dynamic>? ?? {};

      final bookingId =
          _parseInt(json['booking_id']) ??
          _parseInt(booking['booking_id']) ??
          0;

      return ChatMessage(
        id: _parseInt(json['id']) ?? 0,

        bookingId: bookingId,
        bookingNumber: _parseString(booking['booking_number']) ?? '',
        serviceCategory: _parseString(booking['service_category']) ?? '',

        senderId: _parseInt(sender['sender_id']) ?? 0,
        senderRole: _parseString(sender['sender_role']) ?? '',
        senderName: _parseString(sender['sender_name']) ?? '',
        senderAvatar: _parseString(sender['sender_avatar']) ?? '',

        type: MessageType.fromString(_parseString(json['type']) ?? 'TEXT'),
        content: _parseString(json['content']) ?? '',
        isRead: _parseBool(json['is_read']) ?? false,

        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      );
    } catch (error, stackTrace) {
      print('Error parsing ChatMessage: $error');
      print('Stack trace: $stackTrace');
      print('JSON: $json');
      throw FormatException('Failed to parse ChatMessage: $error');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking': {
        'booking_number': bookingNumber,
        'service_category': serviceCategory,
      },
      'sender': {
        'sender_id': senderId,
        'sender_role': senderRole,
        'sender_name': senderName,
        'sender_avatar': senderAvatar,
      },
      'type': type.value,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isTextMessage => type == MessageType.text;

  bool get isImageMessage => type == MessageType.image;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ChatMessage(id: $id, bookingId: $bookingId, '
        'type: ${type.value}, senderId: $senderId)';
  }
}

class SendMessageRequest {
  final int bookingId;
  final String content;
  final MessageType type;

  const SendMessageRequest({
    required this.bookingId,
    required this.content,
    this.type = MessageType.text,
  });

  bool validate() {
    if (bookingId <= 0) return false;
    if (type == MessageType.text && content.trim().isEmpty) return false;
    return true;
  }

  Map<String, dynamic> toJson() {
    return {'booking_id': bookingId, 'content': content, 'type': type.value};
  }

  @override
  String toString() {
    return 'SendMessageRequest(bookingId: $bookingId, type: ${type.value})';
  }
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

String? _parseString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool? _parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  try {
    if (value is DateTime) {
      return value.toLocal();
    }

    if (value is String) {
      final parsed = DateTime.parse(value);

      return parsed.toLocal();
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    }
  } catch (e) {
    print('Error parsing datetime: $value - $e');
    return null;
  }

  return null;
}
