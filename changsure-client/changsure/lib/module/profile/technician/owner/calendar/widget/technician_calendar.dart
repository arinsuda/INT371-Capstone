import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../../../../core/booking/legend_item.dart';
import '../../../../../../core/theme.dart';
import '../../../../../../data/models/booking/booking_model.dart';
import '../../../../../../state/booking_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class TechnicianCalendar extends ConsumerStatefulWidget {
  final DateTime? selectedDay;
  final Function(DateTime)? onDaySelected;
  final Function(DateTime, List<TimeSlot>)? onDayDataSelected;

  const TechnicianCalendar({
    super.key,
    this.selectedDay,
    this.onDaySelected,
    this.onDayDataSelected,
  });

  @override
  ConsumerState<TechnicianCalendar> createState() => _TechnicianCalendarState();
}

class _TechnicianCalendarState extends ConsumerState<TechnicianCalendar> {
  DateTime focusedDay = DateTime.now();
  final now = DateTime.now();
  DateTime? _selectedDay;

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

    _selectedDay = widget.selectedDay;
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

  Widget _buildCalendarLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          /// ฝั่งซ้าย
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              LegendItem(color: Color(0xFFD9D9D9), text: 'ไม่เปิดรับบริการ'),
              SizedBox(height: 12),
              LegendItem(color: AppColors.colorError, text: 'คิวเต็ม'),
            ],
          ),
          SizedBox(width: 70),

          /// ฝั่งขวา
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              LegendItem(
                color: AppColors.primary, // primary
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

  Widget _buildCalendarContent(Map<DateTime, PublicCalendarDay> calendarMap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildCalendarHeader(),
          _buildTableCalendar(calendarMap),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "เปิดรับงาน",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primary,
                  ),
                ),
                Builder(
                  builder: (context) {
                    if (_selectedDay == null) {
                      return const SizedBox();
                    }

                    final normalized = DateTime(
                      _selectedDay!.year,
                      _selectedDay!.month,
                      _selectedDay!.day,
                    );

                    final selectedData = calendarMap[normalized];

                    final currentStatus =
                        selectedData?.status?.toUpperCase() ?? "AVAILABLED";

                    final bookedSlots = selectedData?.bookedSlots ?? 0;

                    final isOpenFromApi = currentStatus != "CLOSED";

                    // 🔥 ถ้ามีงานจองแล้ว → ห้ามปิด
                    final bool cannotClose = bookedSlots > 0 && isOpenFromApi;

                    return Switch(
                      value: isOpenFromApi,
                      onChanged: cannotClose
                          ? null // ❌ disabled
                          : (value) async {
                              final dateString = DateFormat(
                                'yyyy-MM-dd',
                              ).format(normalized);

                              try {
                                await ref.read(
                                  updateTechnicianCalendarProvider((
                                    date: dateString,
                                    isOpen: value,
                                  )).future,
                                );

                                ref.invalidate(
                                  technicianCalendarProvider((
                                    month:
                                        "${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}",
                                  )),
                                );
                              } catch (e) {
                                debugPrint("Update failed: $e");
                              }
                            },
                      thumbColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.white;
                        }
                        return Colors.white;
                      }),
                      trackColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return AppColors.colorStroke.withOpacity(0.5);
                        }
                        if (states.contains(MaterialState.selected)) {
                          return AppColors.primary;
                        }
                        return AppColors.colorStroke;
                      }),
                      trackOutlineColor: MaterialStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.white;
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
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

  Widget _buildTableCalendar(Map<DateTime, PublicCalendarDay> calendarMap) {
    return TableCalendar(
      rowHeight: 48,
      locale: 'th_TH',
      firstDay: DateTime(now.year - 5, 1, 1),
      lastDay: DateTime(now.year + 5, 12, 31),
      focusedDay: focusedDay,

      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
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

        setState(() {
          _selectedDay = selected;
          focusedDay = focused;
        });

        final data = calendarMap[normalized];

        final timeSlots = data?.timeSlots ?? []; // 🔥 ดึง timeSlots ของวันนั้น

        widget.onDaySelected?.call(selected);
        widget.onDayDataSelected?.call(selected, timeSlots); // 🔥 ส่งออก
      },

      headerVisible: false,

      calendarStyle: const CalendarStyle(
        isTodayHighlighted: false,
        defaultTextStyle: TextStyle(color: AppColors.primaryText),
        disabledTextStyle: TextStyle(color: AppColors.colorStroke),
        cellMargin: EdgeInsets.zero,
        cellPadding: EdgeInsets.zero,
      ),

      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, day, _) {
          final normalized = DateTime(day.year, day.month, day.day);
          final today = DateTime(now.year, now.month, now.day);
          final isToday = normalized == today;

          final data = calendarMap[normalized];

          Color textColor = AppColors.primaryText;

          if (normalized.isBefore(bookingStart) ||
              normalized.isAfter(bookingEnd)) {
            textColor = AppColors.secondaryBorder;
          }

          if (data != null) {
            final status = data.status?.toUpperCase() ?? "";
            if (status == 'CLOSED') {
              textColor = AppColors.secondaryBorder;
            } else if (status == 'FULL') {
              textColor = AppColors.colorError;
            }
          }

          final hasBooked = data?.bookings
              ?.where((b) => b.status?.toUpperCase() != "REJECTED")
              .isNotEmpty ??
              false;


          return SizedBox(
            height: 50,
            width: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday ? AppColors.primary : textColor,
                    fontWeight: FontWeight.normal,
                  ),
                ),

                if (hasBooked)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },


        selectedBuilder: (context, day, _) {
          final normalized = DateTime(day.year, day.month, day.day);
          final data = calendarMap[normalized];

          final validBookings = data?.bookings
              ?.where((b) => b.status?.toUpperCase() != "REJECTED")
              .toList() ??
              [];

          final bookedSlots = validBookings.length;
          final hasBooked = bookedSlots > 0;
          final isFulled = bookedSlots >= 3;


          Color backgroundColor;

          if (isFulled) {
            backgroundColor = AppColors.colorError;
          } else if (bookedSlots == 0) {
            backgroundColor = AppColors.primaryBorder;
          } else {
            backgroundColor = AppColors.secondary;
          }

          return SizedBox(
            width: 36,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                if (hasBooked)
                  Positioned(
                    bottom: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },

      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthKey =
        "${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}";

    final asyncValue = ref.watch(technicianCalendarProvider((month: monthKey)));

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
}
