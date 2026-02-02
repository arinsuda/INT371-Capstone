import 'dart:async';
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
  StreamSubscription? _subscription;

  ChatHistoryNotifier(this.ref, this.bookingId)
    : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _loadMessages();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);

    if (user?.token == null) {
      state = AsyncValue.error(Exception("Unauthorized"), StackTrace.current);
      return;
    }

    try {
      final messages = await service.getChatHistory(user!.token!, bookingId);
      state = AsyncValue.data(messages);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _setupRealtimeListener() {
    _subscription = ref.read(realtimeStreamProvider.stream).listen((event) {
      if (event['type'] == 'NEW_MESSAGE') {
        final data = event['data'];
        if (data != null && data['booking_id'] == bookingId) {
          _handleNewMessage(data);
        }
      } else if (event['type'] == 'CHAT_MESSAGE_READ') {
        final data = event['data'];
        if (data['booking_id'] == bookingId) {
          _handleMessageRead(data);
        }
      }
    });
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    try {
      final newMessage = ChatMessage.fromJson(messageData);
      addMessage(newMessage);
    } catch (e) {
      print("💬 Chat Error Parsing Message: $e");
    }
  }

  void addMessage(ChatMessage newMessage) {
    state.whenData((messages) {
      if (!messages.any((m) => m.id == newMessage.id)) {
        state = AsyncValue.data([newMessage, ...messages]);
      }
    });
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    state.whenData((messages) {
      final messageIds = List<int>.from(data['message_ids'] ?? []);
      if (messageIds.isEmpty) return;

      final updatedMessages = messages.map((msg) {
        if (messageIds.contains(msg.id)) {
          return msg.copyWith(isRead: true);
        }
        return msg;
      }).toList();

      state = AsyncValue.data(updatedMessages);
    });
  }

  void refresh() => _loadMessages();
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

    final result = await AsyncValue.guard(() async {
      final newMessage = await service.sendMessage(
        user!.token!,
        SendMessageRequest(
          bookingId: bookingId,
          content: content,
          type: "TEXT",
        ),
      );

      if (newMessage != null) {
        ref
            .read(chatHistoryProvider(bookingId).notifier)
            .addMessage(newMessage);
      }
    });

    if (result.hasError) state = result;
  }

  Future<void> sendImage(int bookingId, File imageFile) async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      final newMessage = await service.sendMessage(
        user!.token!,
        SendMessageRequest(bookingId: bookingId, content: "", type: "IMAGE"),
        imageFile: imageFile,
      );

      if (newMessage != null) {
        ref
            .read(chatHistoryProvider(bookingId).notifier)
            .addMessage(newMessage);
      }
    });

    state = result;
  }
}

final chatRoomsStateProvider =
    StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoom>>>(
      (ref) => ChatRoomsNotifier(ref),
    );

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final Ref ref;
  StreamSubscription? _subscription;

  ChatRoomsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _loadRooms();
    _setupRealtimeListener();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    final service = ref.read(chatServiceProvider);
    final user = ref.read(userProvider);

    if (user?.token == null) {
      state = AsyncValue.error(Exception("Unauthorized"), StackTrace.current);
      return;
    }

    try {
      final rooms = await service.getChatRooms(user!.token!);
      state = AsyncValue.data(rooms);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _setupRealtimeListener() {
    _subscription = ref.read(realtimeStreamProvider.stream).listen((event) {
      if (event['type'] == 'CHAT_MESSAGE_NEW') {
        _handleNewMessage(event['data']);
      } else if (event['type'] == 'CHAT_MESSAGE_READ') {
        _handleMessageRead(event['data']);
      }
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

          final updatedRoom = oldRoom.copyWith(
            lastMessage: message['content'] ?? oldRoom.lastMessage,
            lastMsgType: message['type'] ?? oldRoom.lastMsgType,
            lastMsgTime: DateTime.parse(message['created_at']),
            unreadCount: oldRoom.unreadCount + 1,
          );

          updatedRooms.removeAt(roomIndex);
          updatedRooms.insert(0, updatedRoom);

          state = AsyncValue.data(updatedRooms);
        } else {
          _loadRooms();
        }
      } catch (e) {
        print("💬 ChatRooms Error: $e");
      }
    });
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    state.whenData((rooms) {
      final bookingId = data['booking_id'];
      final updatedRooms = rooms.map((room) {
        if (room.bookingId == bookingId) {
          return room.copyWith(unreadCount: 0);
        }
        return room;
      }).toList();

      state = AsyncValue.data(updatedRooms);
    });
  }

  void refresh() => _loadRooms();
}
