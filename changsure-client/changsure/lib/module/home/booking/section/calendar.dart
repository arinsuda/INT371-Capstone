import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../../core/booking/legend_item.dart';
import '../../../../core/theme.dart';

class Calendar extends StatefulWidget {
  final DateTime? selectedDay;
  final Function(DateTime) onDaySelected;

  const Calendar({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime focusedDay = DateTime.now();
  DateTime? get selectedDay => widget.selectedDay;


  final Set<DateTime> unavailableDates = {
    DateTime(2025, 12, 8),
    DateTime(2025, 12, 20),
  };

  bool _isUnavailable(DateTime day) {
    return unavailableDates.any((d) => isSameDay(d, day));
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
                onPressed: () {
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _buildCalendarHeader(),
          TableCalendar(
            locale: 'th_TH',
            firstDay: DateTime(2025, 1, 1),
            lastDay: DateTime(2026, 12, 31),
            focusedDay: focusedDay,

            selectedDayPredicate: (day) => isSameDay(selectedDay, day),

            enabledDayPredicate: (day) => !_isUnavailable(day),

            onDaySelected: (selected, focused) {
              if (_isUnavailable(selected)) return;

              widget.onDaySelected(selected);

              setState(() {
                focusedDay = focused;
              });
            },


            headerVisible: false,

            calendarStyle: CalendarStyle(
              isTodayHighlighted: false,
              defaultTextStyle: const TextStyle(color: AppColors.primaryText),
              disabledTextStyle: const TextStyle(color: AppColors.colorStroke),
            ),

            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final isToday = isSameDay(day, DateTime.now());

                return Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: isToday
                          ? AppColors
                                .primary // ✅ today = primary
                          : AppColors.primaryText, // วันปกติ
                    ),
                  ),
                );
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

              disabledBuilder: (context, day, _) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 1, color: AppColors.colorStroke),
          ),

          const SizedBox(height: 16),

          _buildCalendarLegend(),
          // Text(
          //   selectedDay != null
          //       ? '${selectedDay!.day}/${selectedDay!.month}/${selectedDay!.year}'
          //       : 'ยังไม่ได้เลือกวัน',
          // ),
        ],
      ),
    );
  }
}
