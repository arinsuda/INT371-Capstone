import 'chat_model.dart';

class ChatThread {
  final int otherPersonId;
  final String name;
  final String avatar;

  final ChatRoom latestRoom;
  final int totalUnread;
  final List<ChatRoom> rooms;

  const ChatThread({
    required this.otherPersonId,
    required this.name,
    required this.avatar,
    required this.latestRoom,
    required this.totalUnread,
    required this.rooms,
  });
}
