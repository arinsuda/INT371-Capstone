import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../state/chat_provider.dart';
import '../../../../core/theme.dart';
import 'chat_room_page.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "แชท",
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "ค้นหา...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(fontSize: 16),
                      onChanged: (val) {},
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.grey),
                ],
              ),
            ),
          ),

          Expanded(
            child: chatsAsync.when(
              data: (rooms) {
                if (rooms.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: rooms.length,
                  itemBuilder: (ctx, i) {
                    final room = rooms[i];
                    final bool isUnread = room.unreadCount > 0;

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              bookingId: room.bookingId,
                              title: room.otherPersonName,
                            ),
                          ),
                        ).then((_) => ref.refresh(chatRoomsProvider));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: _getAvatarColor(i),
                              backgroundImage: room.otherPersonImg.isNotEmpty
                                  ? NetworkImage(room.otherPersonImg)
                                  : null,
                              child: room.otherPersonImg.isEmpty
                                  ? Image.asset(
                                      "assets/image/Technician.png",
                                      width: 56,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    room.otherPersonName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          room.lastMsgType == "IMAGE"
                                              ? "ส่งรูปภาพ"
                                              : room.lastMessage,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,

                                            color: isUnread
                                                ? Colors.black
                                                : Colors.grey,
                                            fontWeight: isUnread
                                                ? FontWeight.w500
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat(
                                          "HH:mm",
                                        ).format(room.lastMsgTime),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            if (isUnread)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0038A8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            "ยังไม่มีการสนทนา",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFFFFCDD2),
      Color(0xFFFFF9C4),
      Color(0xFFC8E6C9),
      Color(0xFFBBDEFB),
    ];
    return colors[index % colors.length];
  }
}
