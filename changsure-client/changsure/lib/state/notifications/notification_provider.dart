import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/data/models/notification_model.dart';
import 'package:changsure/data/services/notification_service.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:changsure/state/notifications/realtime_provider.dart';

class NotificationState {
  final List<NotificationModel> items;
  final int unreadCount;
  final bool isLoading;

  final int? nextCursor;
  final bool hasMore;

  NotificationState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.nextCursor,
    this.hasMore = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? items,
    int? unreadCount,
    bool? isLoading,
    int? nextCursor,
    bool? hasMore,
    bool clearNextCursor = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
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

    Future.microtask(() => loadInitialData());

    return NotificationState(isLoading: true);
  }

  void _handleNewNotification(dynamic data) {
    if (data == null || data is! Map<String, dynamic>) return;
    try {
      if (data['notification'] != null) {
        final newNoti = NotificationModel.fromJson(
          data['notification'] as Map<String, dynamic>,
        );
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

      final result = await _service.list(token: user!.token!, limit: 20);

      final unreadCount = result.items.where((n) => !n.isRead).length;

      state = state.copyWith(
        items: result.items,

        unreadCount: unreadCount,
        isLoading: false,
        nextCursor: result.nextCursor,
        hasMore: result.hasMore,
      );
    } catch (e) {
      print("Load notification error: $e");
      state = state.copyWith(isLoading: false);
    }
}

  Future<void> loadMore() async {
    final user = ref.read(userProvider);

    if (user?.token == null || !state.hasMore || state.nextCursor == null) {
      return;
    }

    try {
      final result = await _service.list(
        token: user!.token!,
        cursor: state.nextCursor,
        limit: 20,
      );

      if (result.items.isNotEmpty) {
        final newUnread = result.items.where((n) => !n.isRead).length;
        state = state.copyWith(
          items: [...state.items, ...result.items],
          unreadCount: state.unreadCount + newUnread,
          nextCursor: result.nextCursor,
          hasMore: result.hasMore,
          clearNextCursor: result.nextCursor == null,
        );
      } else {
        state = state.copyWith(hasMore: false, clearNextCursor: true);
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
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();

    state = state.copyWith(
      items: updatedItems,
      unreadCount: isCurrentlyUnread
          ? (state.unreadCount - 1).clamp(0, 9999)
          : state.unreadCount,
    );

    try {
      await _service.markOneRead(token: user!.token!, id: id);
    } catch (e) {
      print("Mark read failed: $e");

      await loadInitialData();
    }
  }

  Future<void> readAll() async {
    final user = ref.read(userProvider);
    if (user?.token == null) return;

    final unreadIds = state.items
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();

    if (unreadIds.isEmpty) return;

    final updatedItems = state.items
        .map((n) => n.copyWith(isRead: true))
        .toList();
    state = state.copyWith(items: updatedItems, unreadCount: 0);

    try {
      await _service.readAll(token: user!.token!, unreadIds: unreadIds);
    } catch (e) {
      print("Read all failed: $e");
      await loadInitialData();
    }
  }
}
