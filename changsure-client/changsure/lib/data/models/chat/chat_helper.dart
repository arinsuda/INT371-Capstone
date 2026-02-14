import 'package:intl/intl.dart';
import 'chat_model.dart';
import '../technician/public_technician_model.dart';

// ============================================================================
// CHAT PARTICIPANT INFO
// ============================================================================

/// Information about a chat participant (customer or technician)
class ChatParticipantInfo {
  final int userId;
  final String name;
  final String? avatarUrl;

  const ChatParticipantInfo({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  /// Create from chat room data
  factory ChatParticipantInfo.fromChatRoom(ChatRoom chatRoom) {
    return ChatParticipantInfo(
      userId: chatRoom.otherPersonId,
      name: chatRoom.otherPersonName,
      avatarUrl: chatRoom.otherPersonImg.isNotEmpty
          ? chatRoom.otherPersonImg
          : null,
    );
  }

  /// Create from technician profile
  factory ChatParticipantInfo.fromTechnicianProfile(
    PublicTechnicianProfile profile,
  ) {
    return ChatParticipantInfo(
      userId: profile.id,
      name: profile.fullName,
      avatarUrl: profile.avatarUrl?.isNotEmpty == true
          ? profile.avatarUrl
          : null,
    );
  }

  /// Unknown participant (fallback)
  static const ChatParticipantInfo unknown = ChatParticipantInfo(
    userId: 0,
    name: 'ผู้ใช้',
    avatarUrl: null,
  );

  /// Get display name with fallback
  String get displayName => name.isNotEmpty ? name : 'ผู้ใช้';

  /// Whether participant has an avatar
  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatParticipantInfo &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'ChatParticipantInfo(userId: $userId, name: $name)';
  }
}

// ============================================================================
// CHAT HELPER
// ============================================================================

/// Utility class for chat-related operations
class ChatHelper {
  ChatHelper._(); // Private constructor to prevent instantiation

  // ========== CHAT TITLE FORMATTING ==========

  /// Generate chat title with optional booking number
  ///
  /// Examples:
  /// - "John Doe (BK-12345)"
  /// - "Jane Smith"
  static String getChatTitle({required String name, String? bookingNumber}) {
    final displayName = name.isNotEmpty ? name : 'ผู้ใช้';

    if (bookingNumber != null && bookingNumber.isNotEmpty) {
      return '$displayName ($bookingNumber)';
    }

    return displayName;
  }

  // ========== BOOKING STATUS FORMATTING ==========

  /// Format booking status to Thai display text
  static String formatBookingStatus(String status) {
    final bookingStatus = BookingStatus.fromString(status);

    switch (bookingStatus) {
      case BookingStatus.pending:
        return 'รอดำเนินการ';
      case BookingStatus.confirmed:
        return 'ยืนยันแล้ว';
      case BookingStatus.accepted:
        return 'รับงานแล้ว';
      case BookingStatus.inProgress:
        return 'กำลังดำเนินการ';
      case BookingStatus.waitingPayment:
        return 'รอชำระเงิน';
      case BookingStatus.completed:
        return 'เสร็จสิ้น';
      case BookingStatus.cancelled:
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  /// Get booking status color for UI
  static String getBookingStatusColor(String status) {
    final bookingStatus = BookingStatus.fromString(status);

    switch (bookingStatus) {
      case BookingStatus.pending:
        return '#FFA500'; // Orange
      case BookingStatus.confirmed:
      case BookingStatus.accepted:
        return '#4CAF50'; // Green
      case BookingStatus.inProgress:
        return '#2196F3'; // Blue
      case BookingStatus.waitingPayment:
        return '#FF9800'; // Deep Orange
      case BookingStatus.completed:
        return '#4CAF50'; // Green
      case BookingStatus.cancelled:
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // ========== MESSAGE FORMATTING ==========

  /// Format message preview for chat room list
  /// Truncates long messages and handles different message types
  // static String formatMessagePreview(
  //     String message,
  //     MessageType type, {
  //       required bool isMe,
  //       int maxLength = 50,
  //     }) {
  //   if (type == MessageType.image) {
  //     return isMe ? 'คุณส่งรูปภาพ' : '📷 รูปภาพ';
  //   }
  //
  //   if (message.isEmpty) {
  //     return '';
  //   }
  //
  //   if (isMe) {
  //     return 'คุณ: ${_truncate(message, maxLength)}';
  //   }
  //
  //   return _truncate(message, maxLength);
  // }
  //
  // static String _truncate(String text, int maxLength) {
  //   if (text.length <= maxLength) return text;
  //   return '${text.substring(0, maxLength)}...';
  // }

  static String formatMessagePreview(
    String message,
    MessageType type, {
    int maxLength = 50,
  }) {
    if (type == MessageType.image) {
      return '📷 รูปภาพ';
    }
    if (message.isEmpty) {
      return '';
    }
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength)}...';
  }

  // ========== TIME FORMATTING ==========

  /// Format timestamp for message display
  /// Shows time for today, date for older messages
  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Today - show time only
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    }

    // Yesterday
    if (difference.inDays == 1) {
      return 'เมื่อวาน ${DateFormat('HH:mm').format(timestamp)}';
    }

    // This week - show day name
    if (difference.inDays < 7) {
      return DateFormat('EEEE HH:mm', 'th').format(timestamp);
    }

    // This year - show date without year
    if (timestamp.year == now.year) {
      return DateFormat('d MMM HH:mm', 'th').format(timestamp);
    }

    // Older - show full date
    return DateFormat('d MMM yyyy HH:mm', 'th').format(timestamp);
  }

  /// Format timestamp for chat room list (more compact)
  static String formatRoomTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Today - show time only
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    }

    // Yesterday
    if (difference.inDays == 1) {
      return 'เมื่อวาน';
    }

    // This week - show day name
    if (difference.inDays < 7) {
      return DateFormat('EEEE', 'th').format(timestamp);
    }

    // This year - show date without year
    if (timestamp.year == now.year) {
      return DateFormat('d MMM', 'th').format(timestamp);
    }

    // Older - show full date
    return DateFormat('d/M/yy').format(timestamp);
  }

  /// Get relative time description (e.g., "2 hours ago")
  static String getRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'เมื่อสักครู่';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    }

    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks สัปดาห์ที่แล้ว';
    }

    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months เดือนที่แล้ว';
    }

    final years = (difference.inDays / 365).floor();
    return '$years ปีที่แล้ว';
  }

  // ========== MESSAGE GROUPING ==========

  /// Determine if messages should be grouped together
  /// Groups messages from same sender within 5 minutes
  static bool shouldGroupMessages(ChatMessage current, ChatMessage? previous) {
    if (previous == null) return false;
    if (current.senderId != previous.senderId) return false;

    final timeDiff = current.createdAt.difference(previous.createdAt);
    return timeDiff.inMinutes <= 5;
  }

  /// Check if date separator should be shown
  static bool shouldShowDateSeparator(
    ChatMessage current,
    ChatMessage? previous,
  ) {
    if (previous == null) return true;

    final currentDate = DateTime(
      current.createdAt.year,
      current.createdAt.month,
      current.createdAt.day,
    );

    final previousDate = DateTime(
      previous.createdAt.year,
      previous.createdAt.month,
      previous.createdAt.day,
    );

    return currentDate != previousDate;
  }

  /// Format date separator text
  static String formatDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'วันนี้';
    }

    if (messageDate == yesterday) {
      return 'เมื่อวาน';
    }

    if (date.year == now.year) {
      return DateFormat('d MMMM', 'th').format(date);
    }

    return DateFormat('d MMMM yyyy', 'th').format(date);
  }

  // ========== VALIDATION ==========

  /// Validate message content before sending
  static String? validateMessageContent(String content, MessageType type) {
    if (type == MessageType.text) {
      final trimmed = content.trim();

      if (trimmed.isEmpty) {
        return 'กรุณากรอกข้อความ';
      }

      if (trimmed.length > 5000) {
        return 'ข้อความยาวเกินไป (สูงสุด 5000 ตัวอักษร)';
      }
    }

    return null; // Valid
  }

  // ========== UNREAD COUNT FORMATTING ==========

  /// Format unread count for display
  /// Shows "99+" for counts over 99
  static String formatUnreadCount(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return count.toString();
  }
}
