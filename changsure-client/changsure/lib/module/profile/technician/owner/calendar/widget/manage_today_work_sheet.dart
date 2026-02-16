import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/button/tertiary_button.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme.dart';
import '../../../../../../data/models/booking/booking_model.dart';
import '../../../../../../state/booking_provider.dart';

class ManageTodayWorkSheet extends ConsumerStatefulWidget {
  final DateTime date;

  const ManageTodayWorkSheet({
    super.key,
    required this.date,
  });

  @override
  ConsumerState<ManageTodayWorkSheet> createState() =>
      _ManageTodayWorkSheetState();
}

class _ManageTodayWorkSheetState
    extends ConsumerState<ManageTodayWorkSheet> {

  Set<int> selectedSlotIds = {};
  bool isOpen = false;
  bool isDefaultTime = false;

  bool initialIsOpen = false;
  Set<int> initialSelectedSlotIds = {};

  String? syncedDate; // 🔥 ใช้แทน initialized

  bool get hasChanged {
    return !setEquals(selectedSlotIds, initialSelectedSlotIds) ||
        isOpen != initialIsOpen ||
        isDefaultTime;
  }

  @override
  Widget build(BuildContext context) {
    final monthString = DateFormat('yyyy-MM').format(widget.date);
    final dateString = DateFormat('yyyy-MM-dd').format(widget.date);

    final asyncMonth =
    ref.watch(technicianCalendarProvider((month: monthString)));


    return asyncMonth.when(
      loading: () =>
      const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text("Error: $e")),
      data: (monthData) {
        final PublicCalendarDay? dayData =
        monthData.days.firstWhereOrNull(
              (d) =>
          d.date.year == widget.date.year &&
              d.date.month == widget.date.month &&
              d.date.day == widget.date.day,
        );


        if (dayData == null) {
          return const Center(child: Text("No data"));
        }

        final List<TimeSlot> timeSlots =
            dayData.timeSlots;

        final List<BookingDetail> bookings =
            dayData.bookings;

        final bookedSlots = bookings
            .where((b) => b.status != "REJECTED")
            .length;

        /// 🔥 sync state เฉพาะตอนเปลี่ยนวัน
        if (syncedDate != dateString) {
          syncedDate = dateString;

          isOpen = dayData.status == "AVAILABLE";
          initialIsOpen = dayData.status == "AVAILABLE";

          selectedSlotIds = {
            for (final slot in timeSlots)
              if (slot.isActive) slot.id
          };

          initialSelectedSlotIds = Set.from(selectedSlotIds);
        }

        bool isSlotReallyBooked(int slotId) {
          final booking = bookings
              .firstWhereOrNull(
                  (b) => b.timeSlotId == slotId);

          if (booking == null) return false;
          if (booking.status == "REJECTED")
            return false;

          return true;
        }

        final cannotClose =
            bookedSlots > 0 && isOpen;

        return _buildSheet(
          context,
          timeSlots,
          isSlotReallyBooked,
          cannotClose,
        );
      },
    );
  }

  Widget _buildSheet(
      BuildContext context,
      List<TimeSlot> timeSlots,
      bool Function(int) isSlotReallyBooked,
      bool cannotClose,
      ) {
    final monthString =
    DateFormat('yyyy-MM').format(widget.date);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.6,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(
                top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [

                const Center(
                  child: Text(
                    "จัดการงานวันนี้",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (isOpen) ...[
                  const Text(
                    "เวลาที่สะดวกรับงาน",
                    style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final slot
                      in timeSlots)
                        _TimeChip(
                          text:
                          "${slot.startTime} - ${slot.endTime}",
                          selected:
                          selectedSlotIds
                              .contains(
                              slot.id),
                          isDisabled:
                          isSlotReallyBooked(
                              slot.id),
                          onTap: () {
                            if (isSlotReallyBooked(
                                slot.id))
                              return;

                            setState(() {
                              if (selectedSlotIds
                                  .contains(
                                  slot.id)) {
                                selectedSlotIds
                                    .remove(
                                    slot.id);
                              } else {
                                selectedSlotIds
                                    .add(
                                    slot.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                /// SWITCH
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .spaceBetween,
                  children: [
                    const Text(
                      "เปิดรับงาน",
                      style: TextStyle(
                        fontWeight:
                        FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Switch(
                      value: isOpen,
                      onChanged: cannotClose
                          ? null
                          : (value) async {
                        final dateString =
                        DateFormat('yyyy-MM-dd').format(widget.date);

                        await ref.read(
                          updateTechnicianCalendarProvider((
                          date: dateString,
                          isOpen: value,
                          )).future,
                        );

                        ref.invalidate(
                          technicianCalendarProvider((
                          month: monthString,
                          )),
                        );

                        setState(() => isOpen = value);
                      },

                      /// 👇 เพิ่มตรงนี้
                      thumbColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return Colors.white;
                        }
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white; // ตอนเปิด
                        }
                        return Colors.white; // ตอนปิด
                      }),

                      trackColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.disabled)) {
                          return AppColors.colorStroke.withOpacity(0.5);
                        }
                        if (states.contains(MaterialState.selected)) {
                          return AppColors.primary; // ตอนเปิด
                        }
                        return AppColors.colorStroke; // ตอนปิด
                      }),

                      trackOutlineColor:
                      MaterialStateProperty.resolveWith((states) {
                        return Colors.white;
                      }),
                    ),

                  ],
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),

                  decoration: BoxDecoration(
                    color: AppColors.colorWarning,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_outlined,
                        size: 20,
                        color: Color(0xFFAD6800),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "เมื่อคุณกดบันทึก ระบบจะตั้งค่าช่วงเวลานี้เป็นค่ามาตรฐานสำหรับการ รับงานในทุกวัน",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFAD6800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        "ตั้งค่าช่วงเวลานี้เป็นค่ามาตรฐานในการรับงาน",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: isDefaultTime,
                      onChanged: (bool? value) {
                        setState(() {
                          isDefaultTime = value ?? false;
                        });
                      },
                      side: BorderSide(
                        color: AppColors.primaryBorder, // สีกรอบ
                        width: 1.5,
                      ),
                      fillColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return AppColors.primary;
                        }
                        return Colors.white;
                      }),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child:
                      TertiaryButton(
                        text: "ยกเลิก",
                        onPressed: () =>
                            Navigator.pop(
                                context),
                        padding:
                        const EdgeInsets
                            .symmetric(
                            vertical:
                            8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        text: "บันทึก",
                        padding:
                        const EdgeInsets
                            .symmetric(
                            vertical:
                            8),
                        onPressed:
                        hasChanged
                            ? () async {
                          final formattedDate =
                          DateFormat(
                              'yyyy-MM-dd')
                              .format(
                              widget
                                  .date);

                          await ref
                              .read(
                            updateTechnicianTimeSlotProvider((
                            date:
                            formattedDate,
                            isDefault:
                            isDefaultTime,
                            timeSlotIds:
                            selectedSlotIds
                                .toList(),
                            )).future,
                          );

                          ref.invalidate(
                            technicianCalendarProvider((
                            month:
                            monthString,
                            )),
                          );

                          if (mounted) {
                            Navigator.pop(
                                context,
                                true);
                          }
                        }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _TimeChip extends StatelessWidget {
  final String text;
  final bool selected;
  final bool isDisabled;
  final VoidCallback onTap;

  const _TimeChip({
    required this.text,
    required this.selected,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: isDisabled ? null : onTap, // 🔒 disable tap
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDisabled
                ? AppColors.primaryBorder
                : selected
                ? AppColors.primary
                : AppColors.colorStroke,
          ),
          color: isDisabled
              ? AppColors.primaryBGHover
              : selected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.white,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isDisabled
                ? AppColors.primaryBorder
                : selected
                ? AppColors.primary
                : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
