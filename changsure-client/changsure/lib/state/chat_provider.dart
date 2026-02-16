import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/realtime_events.dart';
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


final chatMessagesProvider =
FutureProvider.family<List<ChatMessage>, int>((ref, roomId) async {
  final user = ref.read(userProvider);

  if (user == null || user.token == null) {
    throw Exception("User not logged in");
  }

  final token = user.token!;

  final service = ref.read(chatServiceProvider);

  return service.getChatMessages(token, roomId);
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
          (event) {
            _handleRealtimeEvent(event);
          },
          onError: (error) {
            print('ChatHistory[$bookingId] Realtime error: $error');
          },
        );
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    try {
      final eventType = event['type'] as String?;
      final eventData = event['data'] as Map<String, dynamic>?;

      if (eventData == null || eventType == null) return;

      switch (eventType) {
        case RealtimeEvents.newMessage:
        case RealtimeEvents.chatMessageNew:
          _handleNewMessage(eventData);
          break;

        case RealtimeEvents.roomRead:
        case RealtimeEvents.chatRoomRead:
          _handleRoomRead(eventData);
          break;

        case RealtimeEvents.messageRead:
        case RealtimeEvents.chatMessageRead:
          _handleMessageRead(eventData);
          break;

        case RealtimeEvents.chatRoomLocked:
          _handleRoomLocked(eventData);
          break;

        default:
          break;
      }
    } catch (error) {
      print('Error handling realtime event: $error');
    }
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    final eventBookingId = _ensureInt(messageData['booking_id']);
    if (eventBookingId != bookingId) return;

    try {
      final currentUserId = _ref.read(userProvider)?.id;
      final parsedData = _normalizeMessageData(messageData);
      final newMessage = ChatMessage.fromJson(parsedData);

      if (newMessage.senderId == currentUserId) {
        print(
          '⏭️ Skipping own message from realtime (already optimistic): ${newMessage.id}',
        );

        _updateOptimisticWithServer(newMessage);
        return;
      }

      _addMessageToState(newMessage);

      if (mounted) {
        _autoMarkAsRead();
      }
    } catch (error) {
      print('❌ Error parsing new message: $error');
    }
  }

  void _updateOptimisticWithServer(ChatMessage serverMessage) {
    state.whenData((messages) {
      final recentThreshold = DateTime.now().subtract(
        const Duration(seconds: 10),
      );

      final optimisticIndex = messages.indexWhere(
        (msg) =>
            msg.id < 0 &&
            msg.content == serverMessage.content &&
            msg.type == serverMessage.type &&
            msg.createdAt.isAfter(recentThreshold),
      );

      if (optimisticIndex != -1) {
        final updated = List<ChatMessage>.from(messages);
        updated[optimisticIndex] = serverMessage;

        if (mounted) {
          state = AsyncValue.data(updated);
          print(
            '✅ Updated optimistic message to server version: ${serverMessage.id}',
          );
        }
      } else {
        final isDuplicate = messages.any((m) => m.id == serverMessage.id);
        if (!isDuplicate) {
          _addMessageToState(serverMessage);
          print('⚠️ No optimistic message found, adding server message');
        } else {
          print('⏭️ Message already exists: ${serverMessage.id}');
        }
      }
    });
  }

  Map<String, dynamic> _normalizeMessageData(Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);

    if (!normalized.containsKey('sender') || normalized['sender'] == null) {
      normalized['sender'] = {
        'sender_id': _ensureInt(data['sender_id']),
        'sender_role': data['sender_role'] ?? '',
        'sender_name': data['sender_name'] ?? '',
        'sender_avatar': data['sender_avatar'] ?? '',
      };
    } else {
      final sender = Map<String, dynamic>.from(normalized['sender']);
      sender['sender_id'] = _ensureInt(sender['sender_id']);
      normalized['sender'] = sender;
    }

    if (!normalized.containsKey('booking') || normalized['booking'] == null) {
      normalized['booking'] = {
        'booking_id': _ensureInt(data['booking_id']),
        'booking_number': data['booking_number'] ?? '',
        'service_category': data['service_category'] ?? '',
      };
    }

    normalized['id'] = _ensureInt(data['id'] ?? data['message_id']);
    normalized['booking_id'] = _ensureInt(data['booking_id']);
    normalized['sender_id'] = _ensureInt(data['sender_id']);
    normalized['is_read'] = data['is_read'] ?? false;

    return normalized;
  }

  int _ensureInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  void _handleMessageRead(Map<String, dynamic> data) {
    final eventBookingId = _ensureInt(data['booking_id']);
    if (eventBookingId != bookingId) return;

    print('✅ Message read event for booking $bookingId');

    state.whenData((messages) {
      final messageIds = _parseMessageIds(data['message_ids']);
      if (messageIds.isEmpty) return;

      print('📖 Marking messages as read: $messageIds');

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
    final eventBookingId = _ensureInt(data['booking_id']);
    if (eventBookingId != bookingId) return;

    print('✅ Room read event for booking $bookingId');

    state.whenData((messages) {
      final currentUserId = _ref.read(userProvider)?.id;
      if (currentUserId == null) return;

      final updatedMessages = messages.map((message) {
        return message.copyWith(isRead: true);
      }).toList();

      if (mounted) {
        state = AsyncValue.data(updatedMessages);
      }
    });
  }

  void addMessage(ChatMessage message) {
    _addMessageToState(message);
  }

  void updateOptimisticMessage(int tempId, ChatMessage serverMsg) {
    state.whenData((messages) {
      final index = messages.indexWhere((m) => m.id == tempId);

      if (index != -1) {
        final newList = List<ChatMessage>.from(messages);
        newList[index] = serverMsg;

        if (mounted) {
          state = AsyncValue.data(newList);
          print(
            '✅ [Direct] Updated temp message $tempId to server ID ${serverMsg.id}',
          );
        }
      } else {
        if (serverMsg.type == MessageType.image) {
          final recentThreshold = DateTime.now().subtract(
            const Duration(seconds: 10),
          );

          final imageIndex = messages.indexWhere(
            (msg) =>
                msg.id < 0 &&
                msg.type == MessageType.image &&
                msg.senderId == serverMsg.senderId &&
                msg.createdAt.isAfter(recentThreshold),
          );

          if (imageIndex != -1) {
            final newList = List<ChatMessage>.from(messages);
            newList[imageIndex] = serverMsg;

            if (mounted) {
              state = AsyncValue.data(newList);
              print(
                '✅ [Fallback] Found and updated image at index $imageIndex',
              );
            }
            return;
          }
        }

        print('⚠️ Temp message $tempId not found in state');
      }
    });
  }

  void markMessageAsError(int tempId) {
    print('❌ [Optimistic] Message $tempId failed to send');

    state.whenData((messages) {
      final newList = messages.where((m) => m.id != tempId).toList();
      if (mounted) {
        state = AsyncValue.data(newList);
      }
    });
  }

  Future<void> refresh() => _loadMessages();

  void _handleRoomLocked(Map<String, dynamic> data) {
    final eventBookingId = _ensureInt(data['booking_id']);
    if (eventBookingId != bookingId) return;

    print('🔒 Room locked event for booking $bookingId');
  }

  void _addMessageToState(ChatMessage newMessage) {
    state.whenData((currentMessages) {
      final isDuplicate = currentMessages.any((m) => m.id == newMessage.id);
      if (isDuplicate) {
        print('⚠️ Duplicate message detected: ${newMessage.id}');
        return;
      }

      if (mounted) {
        state = AsyncValue.data([newMessage, ...currentMessages]);
        print(
          '➕ Added new message to state. Total: ${currentMessages.length + 1}',
        );
      }
    });
  }

  Future<void> _autoMarkAsRead() async {
    try {
      final service = _ref.read(chatServiceProvider);
      final token = _ref.read(userProvider)?.token;

      if (token != null) {
        await service.markRoomAsRead(token, bookingId);
        print('✅ Auto-marked booking $bookingId as read');
      }
    } catch (e) {
      print('⚠️ Failed to auto-mark as read: $e');
    }
  }

  List<int> _parseMessageIds(dynamic messageIds) {
    try {
      if (messageIds is List) {
        return messageIds.map((id) => _ensureInt(id)).toList();
      } else if (messageIds is int) {
        return [messageIds];
      }
      return [];
    } catch (_) {
      return [];
    }
  }
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

    try {
      final rooms = await service.getChatRooms(token);
      if (mounted) {
        state = AsyncValue.data(rooms);
        print('✅ Loaded ${rooms.length} chat rooms');
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
          (event) {
            _handleRealtimeEvent(event);
          },
          onError: (error) {
            print('ChatRooms Realtime error: $error');
          },
        );
  }

  void _handleRealtimeEvent(Map<String, dynamic> event) {
    try {
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>?;

      if (type == null || data == null) return;

      print('🔔 ChatRooms Event: $type');

      switch (type) {
        case RealtimeEvents.newMessage:
        case RealtimeEvents.chatMessageNew:
        case RealtimeEvents.chatListUpdated:
          _handleNewMessage(data);
          break;

        case RealtimeEvents.roomRead:
        case RealtimeEvents.chatRoomRead:
          _handleRoomRead(data);
          break;

        case RealtimeEvents.chatRoomUpdated:
          _handleRoomUpdated(data);
          break;

        case RealtimeEvents.chatRoomLocked:
          _handleRoomLocked(data);
          break;

        case RealtimeEvents.bookingStatusChanged:
        case RealtimeEvents.jobCompleted:
        case RealtimeEvents.bookingCancelled:
          _handleBookingStatusChange(data);
          break;

        default:
          if (type.startsWith('BOOKING_')) {
            _handleBookingEvent(type, data);
          }
          break;
      }
    } catch (error, stackTrace) {
      print('Error handling realtime event: $error');
      print(stackTrace);
    }
  }

  void _handleBookingStatusChange(Map<String, dynamic> data) {
    final eventBookingId = _ensureInt(data['booking_id']);
    final status = data['status'] as String?;
    final canChat = data['can_chat'] as bool?;

    print(
      '📦 Booking status changed: $eventBookingId -> $status (canChat: $canChat)',
    );

    state.whenData((rooms) {
      final index = rooms.indexWhere((r) => r.bookingId == eventBookingId);
      if (index == -1) {
        print('⚠️ Room not found, reloading');
        _loadRooms();
        return;
      }

      final updated = List<ChatRoom>.from(rooms);
      final room = updated[index];

      updated[index] = room.copyWith(
        bookingStatus: status != null
            ? BookingStatus.fromString(status)
            : room.bookingStatus,
        canSendMessage: canChat ?? room.canSendMessage,
      );

      if (mounted) {
        state = AsyncValue.data(updated);
        print('✅ Room ${room.bookingNumber} status updated');
      }
    });
  }

  void _handleNewMessage(Map<String, dynamic> messageData) {
    state.whenData((rooms) {
      try {
        final bookingId = _ensureInt(messageData['booking_id']);
        if (bookingId == 0) return;

        print('📩 New message for booking $bookingId');

        final roomIndex = rooms.indexWhere((r) => r.bookingId == bookingId);

        if (roomIndex != -1) {
          _updateExistingRoom(rooms, roomIndex, messageData);
        } else {
          print('⚠️ Room not found, reloading all rooms');
          _loadRooms();
        }
      } catch (error, stackTrace) {
        print('Error handling new message in rooms: $error');
        print(stackTrace);
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

    final lastSender = messageData['last_sender'] as String? ?? '';
    final isMyMessage = lastSender == 'me';

    final shouldIncrementUnread = !isMyMessage;

    print(
      'Updating room ${oldRoom.bookingNumber}: isMyMessage=$isMyMessage, shouldIncrement=$shouldIncrementUnread',
    );

    final updatedRoom = oldRoom.copyWith(
      lastMessage:
          messageData['last_message'] as String? ?? oldRoom.lastMessage,
      lastMsgType: MessageType.fromString(
        messageData['last_msg_type'] as String? ?? oldRoom.lastMsgType.value,
      ),
      lastMsgTime:
          _parseDateTime(messageData['last_msg_time']) ?? oldRoom.lastMsgTime,
      lastSender: lastSender,
      unreadCount: shouldIncrementUnread
          ? oldRoom.unreadCount + 1
          : oldRoom.unreadCount,
    );

    updatedRooms.removeAt(roomIndex);
    updatedRooms.insert(0, updatedRoom);

    if (mounted) {
      state = AsyncValue.data(updatedRooms);
      print('✅ Room updated and moved to top');
    }
  }

  void _handleRoomRead(Map<String, dynamic> data) {
    final eventBookingId = _ensureInt(data['booking_id']);
    if (eventBookingId == 0) return;

    print('✅ Room read event for booking $eventBookingId');

    state.whenData((rooms) {
      final index = rooms.indexWhere((r) => r.bookingId == eventBookingId);
      if (index == -1) {
        print('⚠️ Room not found: $eventBookingId');
        return;
      }

      final updated = List<ChatRoom>.from(rooms);
      final room = updated[index];

      updated[index] = room.copyWith(unreadCount: 0);

      if (mounted) {
        state = AsyncValue.data(updated);
        print('✅ Unread count cleared for ${room.bookingNumber}');
      }
    });
  }

  void _handleRoomUpdated(Map<String, dynamic> data) {
    final eventBookingId = _ensureInt(data['booking_id']);
    final status = data['status'] as String?;

    print('🔄 Room updated event for booking $eventBookingId, status: $status');

    state.whenData((rooms) {
      final index = rooms.indexWhere((r) => r.bookingId == eventBookingId);
      if (index == -1) return;

      final updated = List<ChatRoom>.from(rooms);
      final room = updated[index];

      if (status != null) {
        updated[index] = room.copyWith(
          bookingStatus: BookingStatus.fromString(status),
        );

        if (mounted) {
          state = AsyncValue.data(updated);
        }
      }
    });
  }

  void _handleRoomLocked(Map<String, dynamic> data) {
    final eventBookingId = _ensureInt(data['booking_id']);
    print('🔒 Room locked for booking $eventBookingId');

    _loadRooms();
  }

  void _handleBookingEvent(String eventType, Map<String, dynamic> data) {
    print('📦 Booking event: $eventType');

    _loadRooms();
  }

  int _ensureInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
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
    final text = content.trim();
    if (text.isEmpty) return;

    final historyNotifier = ref.read(chatHistoryProvider(bookingId).notifier);
    final tempId = DateTime.now().millisecondsSinceEpoch * -1;

    final optimisticMsg = _createOptimisticMessage(
      tempId,
      bookingId,
      text,
      MessageType.text,
    );
    historyNotifier.addMessage(optimisticMsg);

    try {
      final serverMsg = await ref
          .read(chatServiceProvider)
          .sendMessage(
            ref.read(userProvider)!.token!,
            SendMessageRequest(
              bookingId: bookingId,
              content: text,
              type: MessageType.text,
            ),
          );

      if (serverMsg != null) {
        historyNotifier.updateOptimisticMessage(tempId, serverMsg);

        print('✅ Message sent successfully: ${serverMsg.id}');
      }
    } catch (e) {
      historyNotifier.markMessageAsError(tempId);
      rethrow;
    }
  }

  Future<void> sendImage(int bookingId, File imageFile) async {
    final historyNotifier = ref.read(chatHistoryProvider(bookingId).notifier);
    final tempId = DateTime.now().millisecondsSinceEpoch * -1;

    final optimisticMsg = _createOptimisticMessage(
      tempId,
      bookingId,
      imageFile.path,
      MessageType.image,
    );
    historyNotifier.addMessage(optimisticMsg);

    try {
      final serverMsg = await ref
          .read(chatServiceProvider)
          .sendMessage(
            ref.read(userProvider)!.token!,
            SendMessageRequest(
              bookingId: bookingId,
              content: '',
              type: MessageType.image,
            ),
            imageFile: imageFile,
          );

      if (serverMsg != null) {
        historyNotifier.updateOptimisticMessage(tempId, serverMsg);
        print('✅ Image sent successfully: ${serverMsg.id}');
      }
    } catch (e) {
      historyNotifier.markMessageAsError(tempId);
      rethrow;
    }
  }

  ChatMessage _createOptimisticMessage(
    int id,
    int bookingId,
    String content,
    MessageType type,
  ) {
    final user = ref.read(userProvider);
    final rooms = ref.read(chatRoomsProvider).value ?? [];
    final currentRoom = rooms.firstWhere(
      (r) => r.bookingId == bookingId,
      orElse: () => throw Exception('Room not found'),
    );

    return ChatMessage(
      id: id,
      bookingId: bookingId,
      content: content,
      type: type,
      senderId: user?.id ?? 0,
      isRead: false,
      createdAt: DateTime.now(),
      bookingNumber: currentRoom.bookingNumber,
      serviceCategory: currentRoom.serviceCategory,
      senderRole: 'customer',
      senderName: user?.fullName ?? '',
      senderAvatar: user?.avatarUrl ?? '',
    );
  }
}
