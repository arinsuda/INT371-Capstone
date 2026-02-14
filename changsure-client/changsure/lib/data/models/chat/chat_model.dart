import 'package:freezed_annotation/freezed_annotation.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum ChatCategory {
  all,
  inProgress,
  completed,
}

/// Message types supported in the chat system
enum MessageType {
  /// Plain text message
  @JsonValue('TEXT')
  text('TEXT'),

  /// Image message
  @JsonValue('IMAGE')
  image('IMAGE');

  const MessageType(this.value);
  final String value;

  /// Create MessageType from string value
  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value.toUpperCase(),
      orElse: () => MessageType.text,
    );
  }
}

/// Booking statuses that are relevant to chat
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

  /// Whether chat is allowed in this booking status
  bool get isChatAllowed {
    return this == BookingStatus.accepted ||
        this == BookingStatus.inProgress ||
        this == BookingStatus.waitingPayment;
  }
}

// ============================================================================
// CHAT ROOM MODEL
// ============================================================================

/// Represents a chat room for a specific booking
/// Contains information about the other participant and the last message
class ChatRoom {
  final int bookingId;
  final String bookingNumber;
  final BookingStatus bookingStatus;
  final int otherPersonId;
  final String otherPersonName;
  final String otherPersonImg;
  final String lastMessage;
  final MessageType lastMsgType;
  final DateTime lastMsgTime;
  final String lastSender;
  final int unreadCount;

  const ChatRoom({
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
    required this.lastSender
  });

  /// Create a copy with modified fields
  ChatRoom copyWith({
    int? bookingId,
    String? bookingNumber,
    BookingStatus? bookingStatus,
    int? otherPersonId,
    String? otherPersonName,
    String? otherPersonImg,
    String? lastMessage,
    MessageType? lastMsgType,
    DateTime? lastMsgTime,
    int? unreadCount,
    String? lastSender
  }) {
    return ChatRoom(
      bookingId: bookingId ?? this.bookingId,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      otherPersonId: otherPersonId ?? this.otherPersonId,
      otherPersonName: otherPersonName ?? this.otherPersonName,
      otherPersonImg: otherPersonImg ?? this.otherPersonImg,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMsgType: lastMsgType ?? this.lastMsgType,
      lastMsgTime: lastMsgTime ?? this.lastMsgTime,
      unreadCount: unreadCount ?? this.unreadCount,
      lastSender: lastSender ?? this.lastSender
    );
  }

  /// Create from JSON with proper error handling
  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    try {
      return ChatRoom(
        bookingId: _parseInt(json['booking_id']) ?? 0,
        bookingNumber: _parseString(json['booking_number']) ?? '',
        bookingStatus: BookingStatus.fromString(
          _parseString(json['booking_status']) ?? 'PENDING',
        ),
        otherPersonId: _parseInt(json['other_person_id']) ?? 0,
        otherPersonName: _parseString(json['other_person_name']) ?? 'Unknown',
        otherPersonImg: _parseString(json['other_person_img']) ?? '',
        lastMessage: _parseString(json['last_message']) ?? '',
        lastMsgType: MessageType.fromString(
          _parseString(json['last_msg_type']) ?? 'TEXT',
        ),
        lastMsgTime: _parseDateTime(json['last_msg_time']) ?? DateTime.now(),
        unreadCount: _parseInt(json['unread_count']) ?? 0,
        lastSender:  _parseString(json['last_sender']) ?? '',
      );
    } catch (error) {
      throw FormatException('Failed to parse ChatRoom: $error');
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'booking_number': bookingNumber,
      'booking_status': bookingStatus.value,
      'other_person_id': otherPersonId,
      'other_person_name': otherPersonName,
      'other_person_img': otherPersonImg,
      'last_message': lastMessage,
      'last_msg_type': lastMsgType.value,
      'last_msg_time': lastMsgTime.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  /// Whether this room has unread messages
  bool get hasUnread => unreadCount > 0;

  /// Whether chat is allowed in this booking
  bool get isChatAllowed => bookingStatus.isChatAllowed;

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

// ============================================================================
// CHAT MESSAGE MODEL
// ============================================================================

/// Represents a single chat message
class ChatMessage {
  final int id;
  final int bookingId;
  final int senderId;
  final String senderRole;
  final MessageType type;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderRole,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  /// Create a copy with modified fields
  ChatMessage copyWith({
    int? id,
    int? bookingId,
    int? senderId,
    String? senderRole,
    MessageType? type,
    String? content,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      type: type ?? this.type,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create from JSON with proper error handling
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    try {
      return ChatMessage(
        id: _parseInt(json['id']) ?? 0,
        bookingId: _parseInt(json['booking_id']) ?? 0,
        senderId: _parseInt(json['sender_id']) ?? 0,
        senderRole: _parseString(json['sender_role']) ?? '',
        type: MessageType.fromString(_parseString(json['type']) ?? 'TEXT'),
        content: _parseString(json['content']) ?? '',
        isRead: _parseBool(json['is_read']) ?? false,
        createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
      );
    } catch (error) {
      throw FormatException('Failed to parse ChatMessage: $error');
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'type': type.value,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Whether this message is a text message
  bool get isTextMessage => type == MessageType.text;

  /// Whether this message is an image
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

// ============================================================================
// REQUEST MODELS
// ============================================================================

/// Request model for sending a message
class SendMessageRequest {
  final int bookingId;
  final String content;
  final MessageType type;

  const SendMessageRequest({
    required this.bookingId,
    required this.content,
    this.type = MessageType.text,
  });

  /// Validate the request
  bool validate() {
    if (bookingId <= 0) return false;
    if (type == MessageType.text && content.trim().isEmpty) return false;
    return true;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {'booking_id': bookingId, 'content': content, 'type': type.value};
  }

  @override
  String toString() {
    return 'SendMessageRequest(bookingId: $bookingId, type: ${type.value})';
  }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/// Safely parse int from dynamic value
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is double) return value.toInt();
  return null;
}

/// Safely parse String from dynamic value
String? _parseString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

/// Safely parse bool from dynamic value
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

/// Safely parse DateTime from dynamic value
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  try {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  } catch (_) {
    return null;
  }

  return null;
}
