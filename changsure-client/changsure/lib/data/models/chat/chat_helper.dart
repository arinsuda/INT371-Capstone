import 'package:changsure/data/models/chat/chat_model.dart';
import 'package:changsure/data/models/technician/public_technician_model.dart';

class ChatHelper {
  static ChatParticipantInfo fromChatRoom(ChatRoom chatRoom) {
    return ChatParticipantInfo(
      userId: chatRoom.otherPersonId,
      name: chatRoom.otherPersonName,
      avatarUrl: chatRoom.otherPersonImg.isNotEmpty
          ? chatRoom.otherPersonImg
          : null,
    );
  }

  static ChatParticipantInfo fromTechnicianProfile(
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

  static String getChatTitle({required String name, String? bookingNumber}) {
    if (bookingNumber != null && bookingNumber.isNotEmpty) {
      return '$name (${bookingNumber})';
    }
    return name;
  }

  static String formatBookingStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'รอดำเนินการ';
      case 'CONFIRMED':
        return 'ยืนยันแล้ว';
      case 'IN_PROGRESS':
        return 'กำลังดำเนินการ';
      case 'COMPLETED':
        return 'เสร็จสิ้น';
      case 'CANCELLED':
        return 'ยกเลิก';
      default:
        return status;
    }
  }
}

class ChatParticipantInfo {
  final int userId;
  final String name;
  final String? avatarUrl;

  const ChatParticipantInfo({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  static ChatParticipantInfo get unknown =>
      const ChatParticipantInfo(userId: 0, name: 'ผู้ใช้', avatarUrl: null);
}
