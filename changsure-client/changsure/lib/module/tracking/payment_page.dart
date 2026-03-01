import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../state/booking_provider.dart';
import 'tracking_card.dart';

class PaymentPage extends ConsumerWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(
      myBookingsProvider((status: 'WAITING_PAYMENT', page: 1)),
    );

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(error.toString()),
            ElevatedButton(
              onPressed: () => ref.invalidate(myBookingsProvider),
              child: const Text('ลองอีกครั้ง'),
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
                  Image.asset("assets/image/noPayment.png", width: 300),
                  const SizedBox(height: 12),
                  const Text(
                    'ยังไม่มีงานที่รอชำระเงิน',
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
