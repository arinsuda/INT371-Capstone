import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/chat/chat_helper.dart';
import '../../../../data/models/chat/chat_model.dart';
import '../../../../data/services/chat_service.dart';
import '../../../../state/chat_provider.dart';
import '../../../../core/theme.dart';
import 'chat_room_page.dart';

final chatSearchQueryProvider = StateProvider<String>((ref) => '');
final chatCategoryProvider = StateProvider<ChatCategory>(
  (ref) => ChatCategory.all,
);

final filteredChatRoomsProvider = Provider<AsyncValue<List<ChatRoom>>>((ref) {
  final roomsAsync = ref.watch(chatRoomsProvider);
  final searchQuery = ref.watch(chatSearchQueryProvider).toLowerCase();
  final category = ref.watch(chatCategoryProvider);

  return roomsAsync.when(
    data: (rooms) {
      var filteredRooms = rooms.where((room) {
        switch (category) {
          case ChatCategory.inProgress:
            return [
              BookingStatus.accepted,
              BookingStatus.inProgress,
              BookingStatus.waitingPayment,
            ].contains(room.bookingStatus);

          case ChatCategory.completed:
            return room.bookingStatus == BookingStatus.completed;

          case ChatCategory.all:
          default:
            return true;
        }
      }).toList();

      if (searchQuery.isNotEmpty) {
        filteredRooms = filteredRooms.where((room) {
          return room.otherPersonName.toLowerCase().contains(searchQuery) ||
              room.bookingNumber.toLowerCase().contains(searchQuery) ||
              room.lastMessage.toLowerCase().contains(searchQuery);
        }).toList();
      }

      return AsyncValue.data(filteredRooms);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final chatCategoryUnreadProvider = Provider<Map<ChatCategory, bool>>((ref) {
  final roomsAsync = ref.watch(chatRoomsProvider);

  return roomsAsync.maybeWhen(
    data: (rooms) {
      bool hasUnread(ChatCategory category) {
        return rooms.any((room) {
          if (!room.hasUnread) return false;

          switch (category) {
            case ChatCategory.inProgress:
              return [
                BookingStatus.accepted,
                BookingStatus.inProgress,
                BookingStatus.waitingPayment,
              ].contains(room.bookingStatus);

            case ChatCategory.completed:
              return room.bookingStatus == BookingStatus.completed;

            case ChatCategory.all:
            default:
              return true;
          }
        });
      }

      return {
        ChatCategory.all: hasUnread(ChatCategory.all),
        ChatCategory.inProgress: hasUnread(ChatCategory.inProgress),
        ChatCategory.completed: hasUnread(ChatCategory.completed),
      };
    },
    orElse: () => {
      ChatCategory.all: false,
      ChatCategory.inProgress: false,
      ChatCategory.completed: false,
    },
  );
});

class ChatListPage extends ConsumerStatefulWidget {
  const ChatListPage({super.key});

  @override
  ConsumerState<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends ConsumerState<ChatListPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(chatSearchQueryProvider.notifier).state = _searchController.text;
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  Future<void> _refreshChatRooms() async {
    ref.invalidate(chatRoomsProvider);
  }

  void _navigateToChatRoom(ChatRoom room) async {
    _searchFocusNode.unfocus();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          bookingId: room.bookingId,
          title: room.otherPersonName,
          otherPersonImg: room.otherPersonImg,
        ),
      ),
    );

    if (mounted) {
      _refreshChatRooms();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final filteredRoomsAsync = ref.watch(filteredChatRoomsProvider);
    final totalUnreadCount = ref
        .watch(chatRoomsProvider.notifier)
        .totalUnreadCount;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _ChatListAppBar(unreadCount: totalUnreadCount),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            onClear: _clearSearch,
          ),

          _CategoryTabs(),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshChatRooms,
              child: filteredRoomsAsync.when(
                data: (rooms) {
                  if (rooms.isEmpty) {
                    final hasSearchQuery = _searchController.text.isNotEmpty;
                    return _EmptyStateView(
                      isSearchResult: hasSearchQuery,
                      onClearSearch: hasSearchQuery ? _clearSearch : null,
                    );
                  }

                  return _ChatRoomsList(
                    rooms: rooms,
                    onRoomTap: _navigateToChatRoom,
                  );
                },
                loading: () => const _LoadingView(),
                error: (error, stack) =>
                    _ErrorView(error: error, onRetry: _refreshChatRooms),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final int unreadCount;

  const _ChatListAppBar({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: true,
      toolbarHeight: 80,
      title: const SizedBox.shrink(),

      flexibleSpace: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "แชท",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ChatHelper.formatUnreadCount(unreadCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
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
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: "ค้นหา",
                  hintStyle: TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            const Icon(Icons.search, color: Colors.grey),

            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                onPressed: onClear,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatRoomsList extends StatelessWidget {
  final List<ChatRoom> rooms;
  final ValueChanged<ChatRoom> onRoomTap;

  const _ChatRoomsList({required this.rooms, required this.onRoomTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 16),
      itemCount: rooms.length,
      itemBuilder: (context, index) {
        final room = rooms[index];
        return _ChatRoomListItem(
          room: room,
          onTap: () => onRoomTap(room),
          colorIndex: index,
        );
      },
    );
  }
}

class _ChatRoomListItem extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback onTap;
  final int colorIndex;

  const _ChatRoomListItem({
    required this.room,
    required this.onTap,
    required this.colorIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = room.hasUnread;
    final isMyMessage = room.lastSender == "me";
    final preview = ChatHelper.formatMessagePreview(
      room.lastMessage,
      room.lastMsgType,
      isMe: isMyMessage,
    );

    final isLocked = !room.canSendMessage;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                _RoomAvatar(
                  imageUrl: room.otherPersonImg,
                  colorIndex: colorIndex,
                ),

                if (isLocked)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.bookingNumber,
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'คุณ ${room.otherPersonName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F4FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                room.serviceCategory,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF007AFF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        ChatHelper.formatRoomTime(room.lastMsgTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread
                              ? AppColors.primary
                              : AppColors.primaryBorder,
                          fontWeight: isUnread
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Expanded(
                        child: preview.isEmpty
                            ? const SizedBox.shrink()
                            : Text(
                                "$preview",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isUnread
                                      ? Colors.black87
                                      : Colors.grey,
                                  fontWeight: isUnread
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                      ),

                      if (isUnread) ...[
                        const SizedBox(width: 8),
                        _UnreadBadge(count: room.unreadCount),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomAvatar extends StatelessWidget {
  final String imageUrl;
  final int colorIndex;

  const _RoomAvatar({required this.imageUrl, required this.colorIndex});

  Color _getAvatarColor(int index) {
    const colors = [
      Color(0xFFFFCDD2),
      Color(0xFFFFF9C4),
      Color(0xFFC8E6C9),
      Color(0xFFBBDEFB),
      Color(0xFFE1BEE7),
      Color(0xFFFFCCBC),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 35,
      backgroundColor: _getAvatarColor(colorIndex),
      backgroundImage: imageUrl.isNotEmpty
          ? NetworkImage(imageUrl)
          : AssetImage('assets/image/Technician.png') as ImageProvider,
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      constraints: const BoxConstraints(minWidth: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0038A8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        ChatHelper.formatUnreadCount(count),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EmptyStateView extends StatelessWidget {
  final bool isSearchResult;
  final VoidCallback? onClearSearch;

  const _EmptyStateView({required this.isSearchResult, this.onClearSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isSearchResult
              ? Icon(Icons.search_off, size: 80, color: Colors.grey[300])
              : Image.asset("assets/image/noChat.png", width: 300),

          const SizedBox(height: 16),
          Text(
            isSearchResult ? "ไม่พบผลการค้นหา" : "ยังไม่มีข้อความในขณะนี้",
            style: TextStyle(
              color: AppColors.primaryBorder,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isSearchResult && onClearSearch != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onClearSearch,
              icon: const Icon(Icons.clear),
              label: const Text('ล้างการค้นหา'),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  String _getErrorMessage(Object error) {
    if (error is NetworkException) {
      return 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต\nกรุณาตรวจสอบการเชื่อมต่อ';
    } else if (error is AuthenticationException) {
      return 'กรุณาเข้าสู่ระบบอีกครั้ง';
    } else if (error is ChatServiceException) {
      return error.message;
    }
    return 'เกิดข้อผิดพลาดที่ไม่คาดคิด';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'ไม่สามารถโหลดรายการแชทได้',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _getErrorMessage(error),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends ConsumerWidget {
  const _CategoryTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(chatCategoryProvider);
    final unreadMap = ref.watch(chatCategoryUnreadProvider);

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
      child: Row(
        children: [
          _buildTab(
            ref,
            label: 'ทั้งหมด',
            value: ChatCategory.all,
            selected: selected,
            hasUnread: unreadMap[ChatCategory.all] ?? false,
          ),
          const SizedBox(width: 12),
          _buildTab(
            ref,
            label: 'กำลังดำเนินการ',
            value: ChatCategory.inProgress,
            selected: selected,
            hasUnread: unreadMap[ChatCategory.inProgress] ?? false,
          ),
          const SizedBox(width: 12),
          _buildTab(
            ref,
            label: 'เสร็จสิ้น',
            value: ChatCategory.completed,
            selected: selected,
            hasUnread: unreadMap[ChatCategory.completed] ?? false,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    WidgetRef ref, {
    required String label,
    required ChatCategory value,
    required ChatCategory selected,
    required bool hasUnread,
  }) {
    final isSelected = value == selected;

    return GestureDetector(
      onTap: () {
        ref.read(chatCategoryProvider.notifier).state = value;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDF9FF) : AppColors.primaryBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.colorStroke,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasUnread) ...[
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  color: AppColors.colorError,
                  shape: BoxShape.circle,
                ),
              ),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
