import 'package:changsure/data/models/notification_model.dart';
import 'package:changsure/module/home/booking/booking_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/state/notifications/notification_provider.dart';
import '../../../core/theme.dart';
import '../../../state/bottom_nav_provider.dart';
import 'widgets/notification_item.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState
    extends ConsumerState<NotificationListScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final notifier = ref.read(notificationProvider.notifier);


    void onNotificationTap(NotificationModel item) {
      if (!item.isRead) {
        notifier.markAsRead(item.id);
      }

      if (item.entityType == 'booking' && item.entityId != null) {
        ref.read(bottomNavIndexProvider.notifier).state = 1;

        Navigator.pop(context);

        print("🚀 Navigate to Booking ID: ${item.entityId}");
      }
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Text(
          'การแจ้งเตือน',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () async {
            Navigator.pop(context);
            await ref.read(notificationProvider.notifier).readAll();
          },
        ),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading && state.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.items.isEmpty) {
            return _buildEmptyState();
          }

          final newItems = state.items.where((i) => !i.isRead).toList();

          final oldItems = state.items.where((i) => i.isRead).toList();

          return RefreshIndicator(
            onRefresh: () async => await notifier.loadInitialData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                if (newItems.isNotEmpty) ...[
                  _buildSectionHeader("ใหม่"),
                  ...newItems.map(
                    (item) => NotificationItem(
                      item: item,
                      onTap: () {
                        onNotificationTap(item);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (oldItems.isNotEmpty) ...[
                  _buildSectionHeader("ก่อนหน้านี้"),
                  ...oldItems.map(
                    (item) => NotificationItem(
                      item: item,
                      onTap: () {
                        onNotificationTap(item);
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/image/empty_notification.png', width: 200),
          const SizedBox(height: 24),
          const Text(
            "ยังไม่มีข้อความในขณะนี้",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
