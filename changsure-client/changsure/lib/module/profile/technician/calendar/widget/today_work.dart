import 'package:changsure/core/theme.dart';
import 'package:changsure/module/profile/technician/calendar/widget/service_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../data/models/booking/booking_model.dart';
import '../../../../../state/booking_provider.dart';
import 'manage_today_work_sheet.dart';

class TodayWork extends ConsumerWidget {
  final DateTime selectedDate;
  final List<TimeSlot> timeSlots;
  final int bookedSlots;
  final bool isOpenFromApi;

  const TodayWork({
    super.key,
    required this.selectedDate,
    required this.timeSlots,
    required this.bookedSlots,
    required this.isOpenFromApi,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final asyncValue = ref.watch(
      technicianCalendarByDateProvider((date: formattedDate)),
    );

    return Container(
      width: double.infinity,
      color: AppColors.primaryBGHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "งานวันนี้",
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final monthString = DateFormat(
                      'yyyy-MM',
                    ).format(selectedDate);
                    final formattedDate = DateFormat(
                      'yyyy-MM-dd',
                    ).format(selectedDate);

                    // 1️⃣ invalidate แบบมี parameter
                    ref.invalidate(
                      technicianCalendarProvider((month: monthString)),
                    );

                    try {
                      // 2️⃣ รอโหลดใหม่
                      final monthData = await ref.read(
                        technicianCalendarProvider((month: monthString)).future,
                      );

                      // 3️⃣ หา day ด้วย DateTime comparison
                      final dayData = monthData.days.firstWhere(
                        (e) =>
                            DateFormat('yyyy-MM-dd').format(e.date) ==
                            formattedDate,
                      );
                      final bookings = await ref.read(
                        technicianCalendarByDateProvider((
                          date: formattedDate,
                        )).future,
                      );

                      // 4️⃣ เปิด modal
                      final result = await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ManageTodayWorkSheet(
                          // timeSlots: dayData.timeSlots,
                          date: selectedDate,
                          // bookedSlots: dayData.bookedSlots,
                          // isOpenFromApi: dayData.status != "CLOSED",
                          // bookings: bookings,
                        ),
                      );

                      if (result == true) {
                        ref.invalidate(
                          technicianCalendarByDateProvider((
                            date: formattedDate,
                          )),
                        );
                        ref.invalidate(
                          technicianCalendarProvider((month: monthString)),
                        );
                      }
                    } catch (e) {
                      debugPrint("Error opening modal: $e");
                    }
                  },

                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "จัดการงานวันนี้",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            asyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (err, stack) => Text(
                "เกิดข้อผิดพลาด: $err",
                style: const TextStyle(color: Colors.red),
              ),

              data: (bookings) {
                // ✅ กรอง REJECTED ออก
                final filteredBookings = bookings
                    .where(
                      (b) => b.status != "REJECTED" && b.status != "CANCELLED",
                    )
                    .toList();

                if (filteredBookings.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          "assets/image/no_work_calendar.png",
                          width: 300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "ยังไม่มีงานในขณะนี้",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final sortedBookings = [...filteredBookings]
                  ..sort((a, b) => a.timeSlotId.compareTo(b.timeSlotId));

                return Column(
                  children: sortedBookings
                      .map(
                        (e) =>
                            ServiceCard(booking: e, selectedDate: selectedDate),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
