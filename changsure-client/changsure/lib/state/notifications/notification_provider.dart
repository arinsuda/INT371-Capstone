import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/models/notification_model.dart';
import 'package:changsure/data/services/notification_service.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:changsure/state/notifications/realtime_provider.dart';

class NotificationState {
  final List<NotificationModel> items;
  final int unreadCount;
  final bool isLoading;

  NotificationState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? items,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(() {
      return NotificationNotifier();
    });

class NotificationNotifier extends Notifier<NotificationState> {
  final NotificationService _service = NotificationService();

  @override
  NotificationState build() {
    final user = ref.watch(userProvider);

    if (user == null) {
      return NotificationState(items: [], unreadCount: 0, isLoading: false);
    }

    _setupRealtimeListener();

    Future.microtask(() => loadInitialData());

    return NotificationState(isLoading: true);
  }

  void _setupRealtimeListener() {
    ref.listen(realtimeStreamProvider, (previous, next) {
      next.whenData((event) {
        print("🔔 Socket Event: ${event['type']}");

        if (event['type'] == 'NOTIFICATION_NEW') {
          _handleNewNotification(event['data']);
        } else if (event['type'].toString().startsWith('BOOKING_')) {
          print("🔄 Booking Event detected! Reloading notifications...");
          loadInitialData();
        }
      });
    });
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    try {
      if (data['notification'] != null) {
        final newNoti = NotificationModel.fromJson(data['notification']);

        state = state.copyWith(
          items: [newNoti, ...state.items],
          unreadCount: state.unreadCount + 1,
        );
      }
    } catch (e) {
      print("Error parsing realtime notification: $e");
    }
  }

  Future<void> loadInitialData() async {
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    try {
      state = state.copyWith(isLoading: true);

      final results = await Future.wait([
        _service.list(token: user!.token!, limit: 20),
        _service.getUnreadCount(user.token!),
      ]);

      state = state.copyWith(
        items: results[0] as List<NotificationModel>,
        unreadCount: results[1] as int,
        isLoading: false,
      );
    } catch (e) {
      print("Load notification error: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMore() async {
    final user = ref.read(userProvider);
    if (user?.token == null || state.items.isEmpty) return;

    final lastId = state.items.last.id;

    try {
      final newItems = await _service.list(
        token: user!.token!,
        cursor: lastId,
        limit: 10,
      );

      if (newItems.isNotEmpty) {
        state = state.copyWith(items: [...state.items, ...newItems]);
      }
    } catch (e) {
      print("Load more error: $e");
    }
  }

  Future<void> markAsRead(int id) async {
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    final isCurrentlyUnread = state.items.any((n) => n.id == id && !n.isRead);

    final updatedItems = state.items.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          entityType: n.entityType,
          entityId: n.entityId,
          data: n.data,
          createdAt: n.createdAt,
          isRead: true,
        );
      }
      return n;
    }).toList();

    int newCount = state.unreadCount;
    if (isCurrentlyUnread) {
      newCount = (newCount - 1).clamp(0, 9999);
    }

    state = state.copyWith(items: updatedItems, unreadCount: newCount);

    try {
      await _service.markRead(token: user!.token!, ids: [id]);
    } catch (e) {
      print("Mark read failed: $e");
    }
  }

  Future<void> readAll() async {
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    final updatedItems = state.items.map((n) {
      return NotificationModel(
        id: n.id,
        type: n.type,
        title: n.title,
        message: n.message,
        entityType: n.entityType,
        entityId: n.entityId,
        data: n.data,
        createdAt: n.createdAt,
        isRead: true,
      );
    }).toList();

    state = state.copyWith(items: updatedItems, unreadCount: 0);

    await _service.readAll(user!.token!);
  }
}
