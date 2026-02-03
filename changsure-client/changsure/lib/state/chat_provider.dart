import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat/chat_model.dart';
import '../data/services/chat_service.dart';
import 'user_provider.dart';
import 'notifications/realtime_provider.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatHistoryProvider = StateNotifierProvider.autoDispose
    .family<ChatHistoryNotifier, AsyncValue<List<ChatMessage>>, int>(
      (ref, bookingId) => ChatHistoryNotifier(ref, bookingId),
    );

final chatRoomsProvider =
    StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoom>>>(
      (ref) => ChatRoomsNotifier(ref),
    );

final chatControllerProvider =
    AsyncNotifierProvider.autoDispose<ChatController, void>(ChatController.new);

// ============================================================================
// CHAT HISTORY NOTIFIER
// ============================================================================

class ChatHistoryNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final Ref _ref;
  final int bookingId;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  ChatHistoryNotifier(this._ref, this.bookingId)
    : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() {
    _loadMessages();
    _subscribeToRealtimeEvents();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final service = _ref.read(chatServiceProvider);
    final token = _ref.read(userProvider)?.token;

    if (token == null) {
      state = AsyncValue.error(
        Exception('User not authenticated'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final messages = await service.getChatHistory(token, bookingId);
      state = AsyncValue.data(messages);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _subscribeToRealtimeEvents() {
    _realtimeSubscription = _ref
        .read(realtimeStreamProvider.stream)
        .listen(_handleRealtimeEvent);
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    final eventType = event['type'] as String?;
    final eventData = event['data'] as Map<String, dynamic>?;

    if (eventData == null) return;

    switch (eventType) {
      case 'NEW_MESSAGE':
        _handleNewMessage(eventData);
        break;
      case 'CHAT_MESSAGE_READ':
        _handleMessageRead(eventData);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    if (messageData['booking_id'] != bookingId) return;

    try {
      final newMessage = ChatMessage.fromJson(messageData);
      _addMessageToState(newMessage);
    } catch (error) {
      print('Chat: Error parsing message - $error');
    }
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    if (data['booking_id'] != bookingId) return;

    state.whenData((messages) {
      final messageIds = List<int>.from(data['message_ids'] ?? []);
      if (messageIds.isEmpty) return;

      final updatedMessages = messages.map((message) {
        return messageIds.contains(message.id)
            ? message.copyWith(isRead: true)
            : message;
      }).toList();

      state = AsyncValue.data(updatedMessages);
    });
  }

  void _addMessageToState(ChatMessage newMessage) {
    state.whenData((currentMessages) {
      final isDuplicate = currentMessages.any((m) => m.id == newMessage.id);
      if (isDuplicate) return;

      state = AsyncValue.data([newMessage, ...currentMessages]);
    });
  }

  void addMessage(ChatMessage message) {
    _addMessageToState(message);
  }

  Future<void> refresh() => _loadMessages();
}

// ============================================================================
// CHAT ROOMS NOTIFIER
// ============================================================================

class ChatRoomsNotifier extends StateNotifier<AsyncValue<List<ChatRoom>>> {
  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  ChatRoomsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initialize();
  }

  void _initialize() {
    _loadRooms();
    _subscribeToRealtimeEvents();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    final service = _ref.read(chatServiceProvider);
    final token = _ref.read(userProvider)?.token;

    if (token == null) {
      state = AsyncValue.error(
        Exception('User not authenticated'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final rooms = await service.getChatRooms(token);
      state = AsyncValue.data(rooms);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void _subscribeToRealtimeEvents() {
    _realtimeSubscription = _ref
        .read(realtimeStreamProvider.stream)
        .listen(_handleRealtimeEvent);
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    final eventType = event['type'] as String?;
    final eventData = event['data'] as Map<String, dynamic>?;

    if (eventData == null) return;

    switch (eventType) {
      case 'NEW_MESSAGE':
      case 'CHAT_MESSAGE_NEW':
        _handleNewMessage(eventData);
        break;
      case 'CHAT_MESSAGE_READ':
        _handleMessageRead(eventData);
        break;
    }
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    state.whenData((rooms) {
      try {
        final bookingId = messageData['booking_id'] as int?;
        if (bookingId == null) return;

        final roomIndex = rooms.indexWhere((r) => r.bookingId == bookingId);

        if (roomIndex != -1) {
          _updateExistingRoom(rooms, roomIndex, messageData);
        } else {
          _loadRooms();
        }
      } catch (error) {
        print('Chat: Error handling new message - $error');
      }
    });
  }

  void _updateExistingRoom(
    List<ChatRoom> rooms,
    int roomIndex,
    Map<String, dynamic> messageData,
  ) {
    final updatedRooms = List<ChatRoom>.from(rooms);
    final oldRoom = updatedRooms[roomIndex];

    final senderId = messageData['sender_id'] as int?;
    final currentUserId = _ref.read(userProvider)?.id;
    final shouldIncrementUnread = senderId != null && senderId != currentUserId;

    final updatedRoom = oldRoom.copyWith(
      lastMessage: messageData['content'] as String? ?? oldRoom.lastMessage,
      lastMsgType: messageData['type'] as String? ?? oldRoom.lastMsgType,
      lastMsgTime:
          _parseDateTime(messageData['created_at']) ?? oldRoom.lastMsgTime,
      unreadCount: shouldIncrementUnread
          ? oldRoom.unreadCount + 1
          : oldRoom.unreadCount,
    );

    updatedRooms.removeAt(roomIndex);
    updatedRooms.insert(0, updatedRoom);

    state = AsyncValue.data(updatedRooms);
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    final bookingId = data['booking_id'] as int?;
    if (bookingId == null) return;

    state.whenData((rooms) {
      final updatedRooms = rooms.map((room) {
        return room.bookingId == bookingId
            ? room.copyWith(unreadCount: 0)
            : room;
      }).toList();

      state = AsyncValue.data(updatedRooms);
    });
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() => _loadRooms();
}

// ============================================================================
// CHAT CONTROLLER
// ============================================================================

class ChatController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMessage(int bookingId, String content) async {
    if (content.trim().isEmpty) return;

    final service = ref.read(chatServiceProvider);
    final token = ref.read(userProvider)?.token;

    if (token == null) {
      throw Exception('User not authenticated');
    }

    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      final newMessage = await service.sendMessage(
        token,
        SendMessageRequest(
          bookingId: bookingId,
          content: content.trim(),
          type: 'TEXT',
        ),
      );

      if (newMessage != null) {
        ref
            .read(chatHistoryProvider(bookingId).notifier)
            .addMessage(newMessage);
      }
    });

    state = result;
  }

  Future<void> sendImage(int bookingId, File imageFile) async {
    final service = ref.read(chatServiceProvider);
    final token = ref.read(userProvider)?.token;

    if (token == null) {
      throw Exception('User not authenticated');
    }

    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      final newMessage = await service.sendMessage(
        token,
        SendMessageRequest(bookingId: bookingId, content: '', type: 'IMAGE'),
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
