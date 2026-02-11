import 'dart:async';
import 'dart:io';

import 'package:changsure/data/models/chat/chat_thread.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/chat/chat_model.dart';
import '../data/services/chat_service.dart';
import 'user_provider.dart';
import 'notifications/realtime_provider.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

/// Provider for chat history of a specific booking
/// Auto-disposes when no longer used to free resources
final chatHistoryProvider = StateNotifierProvider.autoDispose
    .family<ChatHistoryNotifier, AsyncValue<List<ChatMessage>>, int>(
      (ref, bookingId) => ChatHistoryNotifier(ref, bookingId),
    );

/// Provider for all chat rooms
final chatRoomsProvider =
    StateNotifierProvider<ChatRoomsNotifier, AsyncValue<List<ChatRoom>>>(
      (ref) => ChatRoomsNotifier(ref),
    );

/// Controller for chat actions (send messages, images)
final chatControllerProvider =
    AsyncNotifierProvider.autoDispose<ChatController, void>(ChatController.new);

final chatThreadsProvider = Provider<AsyncValue<List<ChatThread>>>((ref) {
  final roomsAsync = ref.watch(chatRoomsProvider);

  return roomsAsync.whenData((rooms) {
    final grouped = <int, List<ChatRoom>>{};

    for (final room in rooms) {
      grouped.putIfAbsent(room.otherPersonId, () => []).add(room);
    }

    final threads = grouped.entries.map((entry) {
      final sorted = [...entry.value]
        ..sort((a, b) => b.lastMsgTime.compareTo(a.lastMsgTime));

      final latest = sorted.first;

      return ChatThread(
        otherPersonId: entry.key,
        name: latest.otherPersonName,
        avatar: latest.otherPersonImg,
        latestRoom: latest,
        totalUnread: sorted.fold(0, (s, r) => s + r.unreadCount),
        rooms: sorted,
      );
    }).toList();

    threads.sort(
      (a, b) => b.latestRoom.lastMsgTime.compareTo(a.latestRoom.lastMsgTime),
    );

    return threads;
  });
});

// ============================================================================
// CHAT HISTORY NOTIFIER
// ============================================================================

/// Manages chat message history for a specific booking
/// Handles real-time updates and message synchronization
class ChatHistoryNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final Ref _ref;
  final int bookingId;
  StreamSubscription<Map<String, dynamic>>? _realtimeSubscription;

  ChatHistoryNotifier(this._ref, this.bookingId)
    : super(const AsyncValue.loading()) {
    _initialize();
  }

  /// Initialize the notifier by loading messages and subscribing to real-time events
  void _initialize() {
    _loadMessages();
    _subscribeToRealtimeEvents();
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  /// Load chat messages from the server
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

  /// Subscribe to real-time events for instant message updates
  void _subscribeToRealtimeEvents() {
    _realtimeSubscription = _ref
        .read(realtimeStreamProvider.stream)
        .listen(
          _handleRealtimeEvent,
          onError: (error) {
            // Log error but don't crash the app
            _logError('Realtime subscription error', error);
          },
        );
  }

  /// Handle incoming real-time events
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
          // Ignore unknown event types
          break;
      }
    } catch (error, stackTrace) {
      _logError('Error handling realtime event', error, stackTrace);
    }
  }

  /// Handle new message event
  void _handleNewMessage(Map<String, dynamic> messageData) {
    // Only process messages for this booking
    if (messageData['booking_id'] != bookingId) return;

    try {
      final newMessage = ChatMessage.fromJson(messageData);
      _addMessageToState(newMessage);
    } catch (error, stackTrace) {
      _logError('Error parsing new message', error, stackTrace);
    }
  }

  /// Handle message read event
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

  /// Handle room read event (marks all messages as read)
  void _handleRoomRead(Map<String, dynamic> data) {
    if (data['booking_id'] != bookingId) return;

    state.whenData((messages) {
      final currentUserId = _ref.read(userProvider)?.id;
      if (currentUserId == null) return;

      // Mark all messages not sent by current user as read
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

  /// Add a message to the current state if it doesn't already exist
  void _addMessageToState(ChatMessage newMessage) {
    state.whenData((currentMessages) {
      // Check for duplicate messages
      final isDuplicate = currentMessages.any((m) => m.id == newMessage.id);
      if (isDuplicate) return;

      // Add new message to the beginning (newest first)
      if (mounted) {
        state = AsyncValue.data([newMessage, ...currentMessages]);
      }
    });
  }

  /// Parse message IDs from dynamic data
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

  /// Log errors for debugging
  void _logError(String context, dynamic error, [StackTrace? stackTrace]) {
    // In production, you might want to send this to a logging service
    print('ChatHistory[$bookingId] $context: $error');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }

  // ========== PUBLIC METHODS ==========

  /// Manually add a message to the state (e.g., optimistic update)
  void addMessage(ChatMessage message) {
    _addMessageToState(message);
  }

  /// Refresh messages from the server
  Future<void> refresh() => _loadMessages();
}

// ============================================================================
// CHAT ROOMS NOTIFIER
// ============================================================================

/// Manages the list of all chat rooms for the current user
/// Handles real-time updates for room state changes
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

  /// Load chat rooms from the server
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

  /// Subscribe to real-time events
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

  /// Handle incoming real-time events
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
          // Ignore unknown event types
          break;
      }
    } catch (error, stackTrace) {
      _logError('Error handling realtime event', error, stackTrace);
    }
  }

  /// Handle new message event
  void _handleNewMessage(Map<String, dynamic> messageData) {
    state.whenData((rooms) {
      try {
        final bookingId = messageData['booking_id'] as int?;
        if (bookingId == null) return;

        final roomIndex = rooms.indexWhere((r) => r.bookingId == bookingId);

        if (roomIndex != -1) {
          // Update existing room
          _updateExistingRoom(rooms, roomIndex, messageData);
        } else {
          // New room appeared, reload all rooms
          _loadRooms();
        }
      } catch (error, stackTrace) {
        _logError('Error handling new message in rooms', error, stackTrace);
      }
    });
  }

  /// Update an existing room with new message data
  void _updateExistingRoom(
    List<ChatRoom> rooms,
    int roomIndex,
    Map<String, dynamic> messageData,
  ) {
    final updatedRooms = List<ChatRoom>.from(rooms);
    final oldRoom = updatedRooms[roomIndex];

    final senderId = messageData['sender_id'] as int?;
    final currentUserId = _ref.read(userProvider)?.id;

    // Only increment unread count if message is from another user
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

    // Move updated room to the top of the list
    updatedRooms.removeAt(roomIndex);
    updatedRooms.insert(0, updatedRoom);

    if (mounted) {
      state = AsyncValue.data(updatedRooms);
    }
  }

  /// Handle room read event
  void _handleRoomRead(Map<String, dynamic> data) {
    final eventBookingId = data['booking_id'];

    state.whenData((rooms) {
      final index = rooms.indexWhere((r) => r.bookingId == eventBookingId);
      if (index == -1) return;

      final updated = List<ChatRoom>.from(rooms);
      final room = updated[index];

      // Reset unread count to 0
      updated[index] = room.copyWith(unreadCount: 0);

      if (mounted) {
        state = AsyncValue.data(updated);
      }
    });
  }

  /// Safely parse DateTime from dynamic value
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  /// Log errors for debugging
  void _logError(String context, dynamic error, [StackTrace? stackTrace]) {
    print('ChatRooms $context: $error');
    if (stackTrace != null) {
      print(stackTrace);
    }
  }

  // ========== PUBLIC METHODS ==========

  /// Refresh rooms from the server
  Future<void> refresh() => _loadRooms();

  /// Get total unread message count across all rooms
  int get totalUnreadCount {
    return state.when(
      data: (rooms) => rooms.fold(0, (sum, room) => sum + room.unreadCount),
      loading: () => 0,
      error: (_, __) => 0,
    );
  }
}

// ============================================================================
// CHAT CONTROLLER
// ============================================================================

/// Controller for performing chat actions like sending messages
class ChatController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Send a text message
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
        // Optimistically add message to local state
        ref
            .read(chatHistoryProvider(bookingId).notifier)
            .addMessage(newMessage);
      }
    });

    state = result;

    // Throw error if the operation failed
    result.when(data: (_) {}, loading: () {}, error: (error, _) => throw error);
  }

  /// Send an image message
  Future<void> sendImage(int bookingId, File imageFile) async {
    // Validate file exists and is readable
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
        // Optimistically add message to local state
        ref
            .read(chatHistoryProvider(bookingId).notifier)
            .addMessage(newMessage);
      }
    });

    state = result;

    // Throw error if the operation failed
    result.when(data: (_) {}, loading: () {}, error: (error, _) => throw error);
  }
}
