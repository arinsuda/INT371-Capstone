import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/button/primary_button.dart';
import '../../../../core/theme.dart';
import '../../../../state/booking_provider.dart';
import 'booking_card.dart';
import 'calendar.dart';

String _formatBookingDate(DateTime day, String time) {
  final thaiMonths = [
    '',
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  return '${day.day} ${thaiMonths[day.month]} ${day.year}, $time';
}

class BookingCalendar extends ConsumerStatefulWidget {
  final DateTime? initialDay;
  final String? initialTime;

  const BookingCalendar({super.key, this.initialDay, this.initialTime});

  @override
  ConsumerState<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends ConsumerState<BookingCalendar> {
  int? selectedTimeSlotId;
  String selectedTime = "";
  DateTime? selectedDay;

  @override
  void initState() {
    super.initState();
    selectedDay = widget.initialDay;
    selectedTime = widget.initialTime ?? "";
  }

  @override
  Widget build(BuildContext context) {
    final timeSlotsAsync = ref.watch(timeSlotsProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          children: [
            Header(header: "เลือกวันรับบริการ"),
            Container(height: 24, color: AppColors.primaryBGHover),

            Calendar(
              selectedDay: selectedDay,
              onDaySelected: (day) {
                setState(() {
                  selectedDay = day;
                });
              },
            ),

            Container(height: 24, color: AppColors.primaryBGHover),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "เลือกช่วงเวลา",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  timeSlotsAsync.when(
                    data: (slots) {
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: slots.map((slot) {
                          return _selectTag(slot.displayText, selectedTime, (
                            v,
                          ) {
                            setState(() {
                              selectedTime = v;
                              selectedTimeSlotId = slot.id; // ✅ เก็บ id จริง
                            });
                          });
                        }).toList(),
                      );
                    },
                    loading: () => const CircularProgressIndicator(),
                    error: (e, _) => Text("โหลดช่วงเวลาไม่สำเร็จ: $e"),
                  ),
                ],
              ),
            ),

            Container(height: 24, color: AppColors.primaryBGHover),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "วันที่นัดหมาย",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (selectedDay != null && selectedTime.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/icons/calendar.svg",
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatBookingDate(selectedDay!, selectedTime),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text(
                      "ยังไม่ได้เลือกวันที่และเวลา",
                      style: TextStyle(color: AppColors.colorStroke),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      /// bottom button
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: PrimaryButton(
          text: "ยืนยัน",
          onPressed: (selectedTime.isEmpty || selectedDay == null)
              ? null
              : () {
                  Navigator.pop(
                    context,
                    BookingDateResult(
                      day: selectedDay!,
                      time: selectedTime,
                      timeSlotId: selectedTimeSlotId!,
                    ),
                  );
                },
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

Widget _selectTag(String label, String current, Function(String) onTap) {
  final bool isSelected = label == current;

  return GestureDetector(
    onTap: () => onTap(label),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isSelected ? AppColors.primaryBGHover : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.colorStroke,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(color: isSelected ? AppColors.primary : Colors.black),
      ),
    ),
  );
}
