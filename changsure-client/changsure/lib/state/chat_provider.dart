import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat/chat_model.dart';
import '../data/services/chat_service.dart';
import 'user_provider.dart';
import 'notifications/realtime_provider.dart';

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

final chatThreadsProvider = Provider<AsyncValue<List<ChatRoom>>>((ref) {
  final roomsAsync = ref.watch(chatRoomsProvider);

  return roomsAsync;
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
      if (mounted) {
        state = AsyncValue.data(messages);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  void _subscribeToRealtimeEvents() {
    _realtimeSubscription = _ref
        .read(realtimeStreamProvider.stream)
        .listen(
          _handleRealtimeEvent,
          onError: (error) {
            _logError('Realtime subscription error', error);
          },
        );
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    try {
      final eventType = event['type'] as String?;
      final eventData = event['data'] as Map<String, dynamic>?;

      if (eventData == null || eventType == null) return;

      switch (eventType) {
        case 'NEW_MESSAGE':
          _handleNewMessage(eventData);
          break;

        case 'CHAT_MESSAGE_READ':
          _handleMessageRead(eventData);
          break;

        case 'ROOM_READ':
          _handleRoomRead(eventData);
          break;

        default:
          break;
      }
    } catch (error, stackTrace) {
      _logError('Error handling realtime event', error, stackTrace);
    }
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    // Check if this message belongs to current booking
    final eventBookingId = messageData['booking_id'];
    if (eventBookingId != bookingId) return;

    try {
      // **FIX: Ensure sender_id is properly structured**
      // The realtime event might have sender data in different structure
      final currentUserId = _ref.read(userProvider)?.id;

      // Debug logging (remove in production)
      print('ChatHistory[$bookingId]: New message event received');
      print('Current user ID: $currentUserId');
      print(
        'Event sender_id: ${messageData['sender_id']} (${messageData['sender_id'].runtimeType})',
      );

      // **FIX: Ensure sender object exists for proper parsing**
      if (!messageData.containsKey('sender')) {
        // If sender object doesn't exist, create it from sender_id
        final senderId = _ensureInt(messageData['sender_id']);
        messageData['sender'] = {
          'sender_id': senderId,
          'sender_role': messageData['sender_role'] ?? '',
          'sender_name': messageData['sender_name'] ?? '',
          'sender_avatar': messageData['sender_avatar'] ?? '',
        };
      } else {
        // Ensure sender_id inside sender object is int
        final senderObj = messageData['sender'] as Map<String, dynamic>;
        senderObj['sender_id'] = _ensureInt(senderObj['sender_id']);
      }

      // **FIX: Ensure booking object exists**
      if (!messageData.containsKey('booking')) {
        messageData['booking'] = {
          'booking_id': eventBookingId,
          'booking_number': messageData['booking_number'] ?? '',
          'service_category': messageData['service_category'] ?? '',
        };
      }

      final newMessage = ChatMessage.fromJson(messageData);

      print(
        'Parsed message - Message ID: ${newMessage.id}, Sender ID: ${newMessage.senderId}, Current User: $currentUserId',
      );
      print('Is my message: ${newMessage.senderId == currentUserId}');

      _addMessageToState(newMessage);
    } catch (error, stackTrace) {
      _logError('Error parsing new message', error, stackTrace);
      print('Raw message data: $messageData');
    }
  }

  // Helper to ensure value is int
  int _ensureInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    if (data['booking_id'] != bookingId) return;

    state.whenData((messages) {
      final messageIds = _parseMessageIds(data['message_ids']);
      if (messageIds.isEmpty) return;

      final updatedMessages = messages.map((message) {
        return messageIds.contains(message.id)
            ? message.copyWith(isRead: true)
            : message;
      }).toList();

      if (mounted) {
        state = AsyncValue.data(updatedMessages);
      }
    });
  }

  void _handleRoomRead(Map<String, dynamic> data) {
    if (data['booking_id'] != bookingId) return;

    state.whenData((messages) {
      final currentUserId = _ref.read(userProvider)?.id;
      if (currentUserId == null) return;

      final updatedMessages = messages.map((message) {
        return message.senderId != currentUserId
            ? message.copyWith(isRead: true)
            : message;
      }).toList();

      if (mounted) {
        state = AsyncValue.data(updatedMessages);
      }
    });
  }

  void _addMessageToState(ChatMessage newMessage) {
    state.whenData((currentMessages) {
      final isDuplicate = currentMessages.any((m) => m.id == newMessage.id);
      if (isDuplicate) return;

      if (mounted) {
        state = AsyncValue.data([newMessage, ...currentMessages]);
      }
    });
  }

  List<int> _parseMessageIds(dynamic messageIds) {
    try {
      if (messageIds is List) {
        return messageIds.whereType<int>().toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  void _logError(String context, dynamic error, [StackTrace? stackTrace]) {
    print('ChatHistory[$bookingId] $context: $error');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }

  void addMessage(ChatMessage message) {
    _addMessageToState(message);
  }

  Future<void> refresh() => _loadMessages();
}

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
      if (mounted) {
        state = AsyncValue.data(rooms);
      }
    } catch (error, stackTrace) {
      if (mounted) {
        state = AsyncValue.error(error, stackTrace);
      }
    }
  }

  void _subscribeToRealtimeEvents() {
    _realtimeSubscription = _ref
        .read(realtimeStreamProvider.stream)
        .listen(
          _handleRealtimeEvent,
          onError: (error) {
            _logError('Realtime subscription error', error);
          },
        );
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    try {
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>?;

      if (type == null || data == null) return;

      switch (type) {
        case 'NEW_MESSAGE':
          _handleNewMessage(data);
          break;

        case 'ROOM_READ':
          _handleRoomRead(data);
          break;

        default:
          break;
      }
    } catch (error, stackTrace) {
      _logError('Error handling realtime event', error, stackTrace);
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
      } catch (error, stackTrace) {
        _logError('Error handling new message in rooms', error, stackTrace);
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
      lastMsgType: MessageType.fromString(
        messageData['type'] as String? ?? oldRoom.lastMsgType.value,
      ),
      lastMsgTime:
          _parseDateTime(messageData['created_at']) ?? oldRoom.lastMsgTime,
      unreadCount: shouldIncrementUnread
          ? oldRoom.unreadCount + 1
          : oldRoom.unreadCount,
    );

    updatedRooms.removeAt(roomIndex);
    updatedRooms.insert(0, updatedRoom);

    if (mounted) {
      state = AsyncValue.data(updatedRooms);
    }
  }

  void _handleRoomRead(Map<String, dynamic> data) {
    final eventBookingId = data['booking_id'];

    state.whenData((rooms) {
      final index = rooms.indexWhere((r) => r.bookingId == eventBookingId);
      if (index == -1) return;

      final updated = List<ChatRoom>.from(rooms);
      final room = updated[index];

      updated[index] = room.copyWith(unreadCount: 0);

      if (mounted) {
        state = AsyncValue.data(updated);
      }
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

  void _logError(String context, dynamic error, [StackTrace? stackTrace]) {
    print('ChatRooms $context: $error');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }

  Future<void> refresh() => _loadRooms();

  int get totalUnreadCount {
    return state.when(
      data: (rooms) => rooms.fold(0, (sum, room) => sum + room.unreadCount),
      loading: () => 0,
      error: (_, __) => 0,
    );
  }
}

class ChatController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendMessage(int bookingId, String content) async {
    if (content.trim().isEmpty) {
      throw Exception('Message cannot be empty');
    }

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
          type: MessageType.text,
        ),
      );

      if (newMessage != null) {
        ref
            .read(chatHistoryProvider(bookingId).notifier)
            .addMessage(newMessage);
      }
    });

    state = result;

    result.when(data: (_) {}, loading: () {}, error: (error, _) => throw error);
  }

  Future<void> sendImage(int bookingId, File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception('Image file does not exist');
    }

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
          content: '',
          type: MessageType.image,
        ),
        imageFile: imageFile,
      );

      if (newMessage != null) {
        ref
            .read(chatHistoryProvider(bookingId).notifier)
            .addMessage(newMessage);
      }
    });

    state = result;

    result.when(data: (_) {}, loading: () {}, error: (error, _) => throw error);
  }
}
