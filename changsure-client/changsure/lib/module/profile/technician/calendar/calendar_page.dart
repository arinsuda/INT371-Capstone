import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/module/profile/technician/calendar/widget/technician_calendar.dart';
import 'package:changsure/module/profile/technician/calendar/widget/today_work.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../../../../data/models/booking/booking_model.dart';
import '../../../../state/booking_provider.dart';
import '../../../../state/user_provider.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  List<TimeSlot> _selectedTimeSlots = [];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final tech = user?.technicianProfile;

    final monthKey =
        "${_selectedDay.year}-${_selectedDay.month.toString().padLeft(2, '0')}";

    final asyncValue = ref.watch(technicianCalendarProvider((month: monthKey)));

    final response = asyncValue.value;

    int totalJobs = 0;

    PublicCalendarDay? selectedDayData;

    if (response != null) {
      selectedDayData = response.days.firstWhereOrNull(
        (e) =>
            e.date.year == _selectedDay.year &&
            e.date.month == _selectedDay.month &&
            e.date.day == _selectedDay.day,
      );

      totalJobs = selectedDayData?.bookedSlots ?? 0;
    }
    final isOpenFromApi =
        (selectedDayData?.status?.toUpperCase() ?? "AVAILABLE") != "CLOSED";

    final selectedBookedSlots = selectedDayData?.bookedSlots ?? 0;

    print("Selected: $_selectedDay");
    print("MonthKey: $monthKey");
    print(
      "Response month: ${response?.days.isNotEmpty == true ? response!.days.first.date : null}",
    );
    final now = DateTime.now();

    final isToday =
        _selectedDay.year == now.year &&
        _selectedDay.month == now.month &&
        _selectedDay.day == now.day;

    final displayText = isToday
        ? "วันนี้"
        : DateFormat('d MMM yy', 'th_TH').format(_selectedDay);

    return Scaffold(
      backgroundColor: AppColors.primaryBGHover,
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        children: [
          Container(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
              child: Column(
                children: [
                  Header(header: "ปฏิทินช่าง"),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 12,
                      left: 12,
                      top: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "สวัสดี ${tech?.firstName} ${tech?.lastName}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              "$displayText คุณมีทั้งหมด",
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.colorTertiaryText,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: totalJobs == 0
                                    ? AppColors.primaryBorder
                                    : const Color(0xFFBAE0FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                "$totalJobs งาน",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: totalJobs == 0
                                      ? AppColors.primaryText
                                      : AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const Spacer(), // ดันไปขวาสุด

                            if (totalJobs >= 3)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.colorError,
                                  ),
                                ),
                                child: const Text(
                                  "คิววันนี้เต็มแล้ว !",
                                  style: TextStyle(
                                    color: AppColors.colorError,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  TechnicianCalendar(
                    selectedDay: _selectedDay,
                    onDaySelected: (date) {
                      setState(() {
                        _selectedDay = date;
                      });
                    },
                    onDayDataSelected: (date, timeSlots) {
                      setState(() {
                        _selectedTimeSlots = timeSlots;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          TodayWork(
            selectedDate: _selectedDay,
            timeSlots: _selectedTimeSlots,
            bookedSlots: selectedBookedSlots,
            isOpenFromApi: isOpenFromApi,
          ),
        ],
      ),
    );
  }
}
