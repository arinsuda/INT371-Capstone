import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat/chat_model.dart';
import '../data/services/chat_service.dart';
import 'user_provider.dart';
import 'notifications/realtime_provider.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final chatHistoryProvider = StateNotifierProvider.autoDispose
    .family<ChatHistoryNotifier, AsyncValue<List<ChatMessage>>, int>((
      ref,
      bookingId,
    ) {
      return ChatHistoryNotifier(ref, bookingId);
    });

class ChatHistoryNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final Ref ref;
  final int bookingId;

  ChatHistoryNotifier(this.ref, this.bookingId)
    : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _loadMessages();
    _setupRealtimeListener();
  }

  Future<void> _loadMessages() async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);

    if (user?.token == null) {
      state = AsyncValue.error(Exception("Unauthorized"), StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final messages = await service.getChatHistory(user!.token!, bookingId);
      state = AsyncValue.data(messages);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _setupRealtimeListener() {
    ref.listen(realtimeStreamProvider, (previous, next) {
      next.whenData((event) {
        print("💬 Chat Event: ${event['type']} for booking $bookingId");

        if (event['type'] == 'CHAT_MESSAGE_NEW') {
          final data = event['data'];
          if (data['booking_id'] == bookingId) {
            _handleNewMessage(data['message']);
          }
        } else if (event['type'] == 'CHAT_MESSAGE_READ') {
          final data = event['data'];
          if (data['booking_id'] == bookingId) {
            _handleMessageRead(data);
          }
        }
      });
    });
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    state.whenData((messages) {
      try {
        final newMessage = ChatMessage.fromJson(messageData);

        final exists = messages.any((m) => m.id == newMessage.id);
        if (!exists) {
          state = AsyncValue.data([newMessage, ...messages]);
        }
      } catch (e) {
        print("Error parsing new message: $e");
      }
    });
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    state.whenData((messages) {
      final messageIds = List<int>.from(data['message_ids'] ?? []);

      final updatedMessages = messages.map((msg) {
        if (messageIds.contains(msg.id)) {
          return ChatMessage(
            id: msg.id,
            bookingId: msg.bookingId,
            senderId: msg.senderId,
            senderRole: msg.senderRole,
            type: msg.type,
            content: msg.content,
            isRead: true,
            createdAt: msg.createdAt,
          );
        }
        return msg;
      }).toList();

      state = AsyncValue.data(updatedMessages);
    });
  }

  void refresh() {
    _loadMessages();
  }
}

final chatControllerProvider =
    AsyncNotifierProvider.autoDispose<ChatController, void>(ChatController.new);

class ChatController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMessage(int bookingId, String content) async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await service.sendMessage(
        user!.token!,
        SendMessageRequest(
          bookingId: bookingId,
          content: content,
          type: "TEXT",
        ),
      );
    });
  }

  Future<void> sendImage(int bookingId, File imageFile) async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await service.sendMessage(
        user!.token!,
        SendMessageRequest(bookingId: bookingId, content: "", type: "IMAGE"),
        imageFile: imageFile,
      );
    });
  }
}

final chatRoomsStateProvider =
    StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoom>>>(
      (ref) => ChatRoomsNotifier(ref),
    );

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final Ref ref;

  ChatRoomsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _loadRooms();
    _setupRealtimeListener();
  }

  Future<void> _loadRooms() async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);

    if (user?.token == null) {
      state = AsyncValue.error(Exception("Unauthorized"), StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final rooms = await service.getChatRooms(user!.token!);
      state = AsyncValue.data(rooms);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _setupRealtimeListener() {
    ref.listen(realtimeStreamProvider, (previous, next) {
      next.whenData((event) {
        print("💬 ChatRooms Event: ${event['type']}");

        if (event['type'] == 'CHAT_MESSAGE_NEW') {
          _handleNewMessage(event['data']);
        } else if (event['type'] == 'CHAT_MESSAGE_READ') {
          _handleMessageRead(event['data']);
        }
      });
    });
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    state.whenData((rooms) {
      try {
        final bookingId = data['booking_id'];
        final message = data['message'];

        final roomIndex = rooms.indexWhere((r) => r.bookingId == bookingId);

        if (roomIndex != -1) {
          final updatedRooms = List<ChatRoom>.from(rooms);
          final oldRoom = updatedRooms[roomIndex];

          updatedRooms[roomIndex] = ChatRoom(
            bookingId: oldRoom.bookingId,
            bookingNumber: oldRoom.bookingNumber,
            bookingStatus: oldRoom.bookingStatus,
            otherPersonId: oldRoom.otherPersonId,
            otherPersonName: oldRoom.otherPersonName,
            otherPersonImg: oldRoom.otherPersonImg,
            lastMessage: message['content'] ?? oldRoom.lastMessage,
            lastMsgType: message['type'] ?? oldRoom.lastMsgType,
            lastMsgTime: message['created_at'] != null
                ? DateTime.parse(message['created_at'])
                : oldRoom.lastMsgTime,
            unreadCount: oldRoom.unreadCount + 1,
          );

          final updatedRoom = updatedRooms.removeAt(roomIndex);
          updatedRooms.insert(0, updatedRoom);

          state = AsyncValue.data(updatedRooms);
        } else {
          _loadRooms();
        }
      } catch (e) {
        print("Error handling new message in chat rooms: $e");
      }
    });
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    state.whenData((rooms) {
      try {
        final bookingId = data['booking_id'];

        final updatedRooms = rooms.map((room) {
          if (room.bookingId == bookingId) {
            return ChatRoom(
              bookingId: room.bookingId,
              bookingNumber: room.bookingNumber,
              bookingStatus: room.bookingStatus,
              otherPersonId: room.otherPersonId,
              otherPersonName: room.otherPersonName,
              otherPersonImg: room.otherPersonImg,
              lastMessage: room.lastMessage,
              lastMsgType: room.lastMsgType,
              lastMsgTime: room.lastMsgTime,
              unreadCount: 0,
            );
          }
          return room;
        }).toList();

        state = AsyncValue.data(updatedRooms);
      } catch (e) {
        print("Error handling message read in chat rooms: $e");
      }
    });
  }

  void refresh() {
    _loadRooms();
  }
}
