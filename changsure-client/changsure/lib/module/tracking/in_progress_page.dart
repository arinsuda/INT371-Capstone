import 'package:changsure/state/booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tracking_card.dart';
import '../../core/theme.dart';

class InProgressPage extends ConsumerWidget {
  const InProgressPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(
      myBookingsProvider((status: 'PENDING,ACCEPTED,IN_PROGRESS', page: 1)),
    );

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),

      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64),
            Text('เกิดข้อผิดพลาด'),
            ElevatedButton(
              onPressed: () => ref.invalidate(myBookingsProvider),
              child: Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),

      data: (bookings) {
        if (bookings.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset("assets/image/noWorkProgress.png", width: 200),
                  const SizedBox(height: 12),
                  const Text(
                    'ยังไม่มีงานที่กำลังดำเนินการ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBorder,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myBookingsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              return TrackingCard(
                booking: bookings[index],
                onViewDetail: () {},
                onTap: () {},
              );
            },
          ),
        );
      },
    );
  }
}
