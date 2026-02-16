import 'package:changsure/module/tracking/tracking_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/booking_provider.dart';

class InProgressPage extends ConsumerStatefulWidget {
  const InProgressPage({super.key});

  @override
  ConsumerState<InProgressPage> createState() => _InProgressPageState();
}

class _InProgressPageState extends ConsumerState<InProgressPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(myBookingsProvider((status: "PENDING", page: 1)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final bookingsAsync = ref.watch(
      myBookingsProvider((status: "PENDING", page: 1)),
    );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myBookingsProvider((status: "PENDING", page: 1)));
      },
      child: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Text(
                "ไม่มีรายการที่กำลังดำเนินการ",
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("เกิดข้อผิดพลาด: $error")),
      ),
    );
  }
}
