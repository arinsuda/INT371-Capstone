import 'package:intl/intl.dart';
import 'chat_model.dart';
import '../technician/public_technician_model.dart';

class ChatParticipantInfo {
  final int userId;
  final String name;
  final String? avatarUrl;

  const ChatParticipantInfo({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  factory ChatParticipantInfo.fromChatRoom(ChatRoom chatRoom) {
    return ChatParticipantInfo(
      userId: chatRoom.otherPersonId,
      name: chatRoom.otherPersonName,
      avatarUrl: chatRoom.otherPersonImg.isNotEmpty
          ? chatRoom.otherPersonImg
          : null,
    );
  }

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

  static const ChatParticipantInfo unknown = ChatParticipantInfo(
    userId: 0,
    name: 'ผู้ใช้',
    avatarUrl: null,
  );

  String get displayName => name.isNotEmpty ? name : 'ผู้ใช้';

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

class ChatHelper {
  ChatHelper._();

  static String getChatTitle({required String name, String? bookingNumber}) {
    final displayName = name.isNotEmpty ? name : 'ผู้ใช้';

    if (bookingNumber != null && bookingNumber.isNotEmpty) {
      return '$displayName ($bookingNumber)';
    }

    return displayName;
  }

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

  static String getBookingStatusColor(String status) {
    final bookingStatus = BookingStatus.fromString(status);

    switch (bookingStatus) {
      case BookingStatus.pending:
        return '#FFA500';
      case BookingStatus.confirmed:
      case BookingStatus.accepted:
        return '#4CAF50';
      case BookingStatus.inProgress:
        return '#2196F3';
      case BookingStatus.waitingPayment:
        return '#FF9800';
      case BookingStatus.completed:
        return '#4CAF50';
      case BookingStatus.cancelled:
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  static String formatMessagePreview(
    String message,
    MessageType type, {
    required bool isMe,
    int maxLength = 50,
  }) {
    if (type == MessageType.image) {
      return isMe ? 'คุณส่งรูปภาพ' : '📷 รูปภาพ';
    }

    if (message.isEmpty) {
      return '';
    }

    if (isMe) {
      return 'คุณ: ${_truncate(message, maxLength)}';
    }

    return _truncate(message, maxLength);
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(timestamp);
    }

    if (difference.inDays == 1) {
      return 'เมื่อวาน ${DateFormat('HH:mm').format(timestamp)}';
    }

    if (difference.inDays < 7) {
      return DateFormat('EEEE HH:mm', 'th').format(timestamp);
    }

    if (timestamp.year == now.year) {
      return DateFormat('d MMM HH:mm', 'th').format(timestamp);
    }

    return DateFormat('d MMM yyyy HH:mm', 'th').format(timestamp);
  }

  static String formatRoomTime(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (msgDay == today) {
      return DateFormat('HH:mm').format(timestamp);
    }

    if (msgDay == today.subtract(const Duration(days: 1))) {
      return 'เมื่อวาน';
    }

    if (diff.inDays < 7) {
      return DateFormat('EEE', 'th').format(timestamp);
    }

    if (timestamp.year == now.year) {
      return DateFormat('d MMM', 'th').format(timestamp);
    }

    return DateFormat('dd/MM/yy').format(timestamp);
  }

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

  static bool shouldGroupMessages(ChatMessage current, ChatMessage? previous) {
    if (previous == null) return false;
    if (current.senderId != previous.senderId) return false;

    final timeDiff = current.createdAt.difference(previous.createdAt);
    return timeDiff.inMinutes <= 5;
  }

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

    return null;
  }

  static String formatUnreadCount(int count) {
    if (count <= 0) return '';
    if (count > 99) return '99+';
    return count.toString();
  }
}
