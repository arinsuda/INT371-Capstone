import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../core/booking/legend_item.dart';
import '../../../../core/theme.dart';
import '../../../../data/models/booking/booking_model.dart';
import '../../../../state/booking_provider.dart';

class Calendar extends ConsumerStatefulWidget {
  final DateTime? selectedDay;
  final Function(DateTime) onDaySelected;
  final int technicianId;

  const Calendar({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    required this.technicianId,
  });

  @override
  ConsumerState<Calendar> createState() => _CalendarState();
}

class _CalendarState extends ConsumerState<Calendar> {
  DateTime focusedDay = DateTime.now();
  final now = DateTime.now();

  DateTime? get selectedDay => widget.selectedDay;
  late final DateTime bookingStart;
  late final DateTime bookingEnd;

  Map<DateTime, PublicCalendarDay> _createCalendarMap(
    List<PublicCalendarDay> days,
  ) {
    final map = <DateTime, PublicCalendarDay>{};

    for (final day in days) {
      final normalized = DateTime(day.date.year, day.date.month, day.date.day);

      map[normalized] = day;
    }

    return map;
  }

  @override
  void initState() {
    super.initState();

    final today = DateTime(now.year, now.month, now.day);

    bookingStart = today;
    bookingEnd = DateTime(today.year, today.month + 1, today.day);
  }

  @override
  Widget build(BuildContext context) {
    final monthKey =
        "${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}";

    final asyncValue = ref.watch(
      publicCalendarProvider((
        technicianId: widget.technicianId,
        month: monthKey,
      )),
    );

    final response = asyncValue.value;
    print(response?.days.map((e) => "${e.date} ${e.status}").toList());


    // 🔴 โหลดครั้งแรกเท่านั้น
    if (response == null) {
      return Container(
        height: 500,
        color: Colors.white.withOpacity(0.6),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final calendarMap = _createCalendarMap(response.days);

    return Stack(
      children: [
        _buildCalendarContent(calendarMap),

        // 🟡 ถ้ากำลังโหลดเดือนใหม่ → show spinner เล็ก ๆ
        if (asyncValue.isLoading)
          Positioned.fill(
            child: Container(
              height: 500,
              color: Colors.white.withOpacity(0.6),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarContent(Map<DateTime, PublicCalendarDay> calendarMap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildCalendarHeader(),
          _buildTableCalendar(calendarMap),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.colorStroke),
          ),
          const SizedBox(height: 16),
          _buildCalendarLegend(),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMMM yyyy', 'th_TH').format(focusedDay),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    focusedDay = DateTime(
                      focusedDay.year,
                      focusedDay.month - 1,
                    );
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed:
                    focusedDay.isAfter(
                      DateTime.now().add(const Duration(days: 365)),
                    )
                    ? null
                    : () {
                        setState(() {
                          focusedDay = DateTime(
                            focusedDay.year,
                            focusedDay.month + 1,
                          );
                        });
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCalendar(Map<DateTime, PublicCalendarDay> calendarMap) {
    return TableCalendar(
      locale: 'th_TH',
      firstDay: DateTime(now.year - 5, 1, 1),
      lastDay: DateTime(now.year + 5, 12, 31),
      focusedDay: focusedDay,

      selectedDayPredicate: (day) => isSameDay(selectedDay, day),

      enabledDayPredicate: (day) {
        final normalizedDay = DateTime(day.year, day.month, day.day);

        if (normalizedDay.isBefore(bookingStart) ||
            normalizedDay.isAfter(bookingEnd)) {
          return false;
        }

        return true;
      },

      onDaySelected: (selected, focused) {
        final normalized = DateTime(
          selected.year,
          selected.month,
          selected.day,
        );

        if (normalized.isBefore(bookingStart) ||
            normalized.isAfter(bookingEnd)) {
          return;
        }
        final data = calendarMap[normalized];

        if (data?.status == 'CLOSED') return;
        if (data?.status == 'FULL') return;

        widget.onDaySelected(selected);

        setState(() {
          focusedDay = focused;
        });
      },

      headerVisible: false,

      calendarStyle: const CalendarStyle(
        isTodayHighlighted: false,
        defaultTextStyle: TextStyle(color: AppColors.primaryText),
        disabledTextStyle: TextStyle(color: AppColors.secondaryBorder),
      ),

      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final today = DateTime(now.year, now.month, now.day);
          final normalized = DateTime(day.year, day.month, day.day);
          final data = calendarMap[normalized];

          print("Calendar day: $normalized ${data?.status}");
          print("Map keys: ${calendarMap.keys}");

          print("Matched data: ${data?.status}");

          Color textColor = AppColors.primaryText;

          if (data != null) {
            final status = data.status?.toUpperCase();
            if (status == 'CLOSED') {
              textColor = AppColors.secondaryBorder; // ❌ ปิดรับ
            } else if (status == 'FULL') {
              textColor = AppColors.colorError; // 🔴 เต็ม
            }
          }

          if (data != null) {
            print("Day: ${day.day}  → status: ${data.status}");
          }

          // 🟢 วันนี้
          if (normalized == today &&
              data?.status != 'CLOSED' &&
              data?.status != 'FULL') {
            textColor = AppColors.primaryText;
          }

          if(normalized == today ) {
            textColor = AppColors.primary;

          }
          return Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: normalized == today
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          );
        },

        disabledBuilder: (context, day, _) {
          return _buildDay(day, calendarMap, isDisabled: true);
        },

        selectedBuilder: (context, day, _) {
          return Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFE1EFFA),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '${day.day}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDay(
    DateTime day,
    Map<DateTime, PublicCalendarDay> calendarMap, {
    required bool isDisabled,
  }) {
    final normalized = DateTime(day.year, day.month, day.day);
    final today = DateTime(now.year, now.month, now.day);

    final data = calendarMap[normalized];

    Color textColor = AppColors.primaryText;

    // 🔴 ถ้าเป็น disabled จากช่วงวัน
    if (isDisabled) {
      textColor = AppColors.colorStroke;
    }

    // 🔵 ถ้ามี status จาก API ให้ override
    if (data != null) {
      final status = data.status?.toUpperCase();

      if (status == 'CLOSED') {
        textColor = AppColors.colorStroke;
      } else if (status == 'FULL') {
        textColor = AppColors.colorError;
      }
    }

    return Center(
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight: normalized == today ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildCalendarLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: const [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegendItem(color: Color(0xFFD9D9D9), text: 'ไม่เปิดรับบริการ'),
              SizedBox(height: 12),
              LegendItem(color: AppColors.colorError, text: 'คิวเต็ม'),
            ],
          ),
          SizedBox(width: 70),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegendItem(
                color: AppColors.primary,
                text: 'วันที่เลือกจองบริการ',
              ),
              SizedBox(height: 12),
              LegendItem(color: AppColors.primaryText, text: 'คิวว่าง'),
            ],
          ),
        ],
      ),
    );
  }
}
