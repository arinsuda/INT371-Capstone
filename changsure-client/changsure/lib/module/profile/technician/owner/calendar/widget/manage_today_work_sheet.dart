import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/button/tertiary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../../core/theme.dart';
import '../../../../../../data/models/booking/booking_model.dart';
import '../../../../../../state/booking_provider.dart';

class ManageTodayWorkSheet extends ConsumerStatefulWidget {
  final List<TimeSlot> timeSlots;
  final DateTime date;
  final int bookedSlots;
  final bool isOpenFromApi;

  const ManageTodayWorkSheet({
    super.key,
    required this.timeSlots,
    required this.date,
    required this.bookedSlots,
    required this.isOpenFromApi,
  });

  @override
  ConsumerState<ManageTodayWorkSheet> createState() =>
      _ManageTodayWorkSheetState();
}

class _ManageTodayWorkSheetState extends ConsumerState<ManageTodayWorkSheet> {
  Set<int> selectedSlotIds = {};
  late bool isOpen;
  bool isDefaultTime = false;
  late bool initialIsOpen;
  late Set<int> initialSelectedSlotIds;

  @override
  void initState() {
    super.initState();

    isOpen = widget.isOpenFromApi;
    initialIsOpen = widget.isOpenFromApi;

    for (final slot in widget.timeSlots) {
      if (slot.isActive) {
        selectedSlotIds.add(slot.id);
      }
    }

    initialSelectedSlotIds = Set.from(selectedSlotIds);
  }

  bool get hasChanged {
    final slotChanged = !setEquals(selectedSlotIds, initialSelectedSlotIds);

    final openChanged = isOpen != initialIsOpen;

    final defaultChanged = isDefaultTime;

    return slotChanged || openChanged || defaultChanged;
  }

  @override
  Widget build(BuildContext context) {
    print(DateFormat('yyyy-MM-dd').format(widget.date));
    final bool isBooked;
    final bool cannotClose = widget.bookedSlots > 0 && isOpen;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.6,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.settings_outlined, size: 16),
                    SizedBox(width: 8),
                    Text(
                      "จัดการงานวันนี้",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (isOpen) ...[
                  const Text(
                    "เวลาที่สะดวกรับงาน",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),

                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final slot in widget.timeSlots)
                        _TimeChip(
                          text: "${slot.startTime} - ${slot.endTime}",
                          selected: selectedSlotIds.contains(slot.id),
                          isDisabled: slot.isBooked, // 👈 เพิ่มตรงนี้
                          onTap: () {
                            if (slot.isBooked) return; // 🔒 กันอีกชั้น

                            setState(() {
                              if (selectedSlotIds.contains(slot.id)) {
                                selectedSlotIds.remove(slot.id);
                              } else {
                                selectedSlotIds.add(slot.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),


                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "เปิดรับงาน",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Switch(
                      value: isOpen,
                      onChanged: cannotClose
                          ? null
                          : (value) async {
                              final dateString = DateFormat(
                                'yyyy-MM-dd',
                              ).format(widget.date);

                              print("data $dateString");

                              try {
                                await ref.read(
                                  updateTechnicianCalendarProvider((
                                    date: dateString,
                                    isOpen: value,
                                  )).future,
                                );

                                setState(() => isOpen = value);
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
                    ),
                  ],
                ),

                const SizedBox(height: 16),
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

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TertiaryButton(
                        text: "ยกเลิก",
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        onPressed: hasChanged
                            ? () async {
                                final formattedDate = DateFormat(
                                  'yyyy-MM-dd',
                                ).format(widget.date);

                                final params = (
                                  date: formattedDate,
                                  isDefault: isDefaultTime,
                                  timeSlotIds: List<int>.from(selectedSlotIds),
                                );

                                try {
                                  await ref.read(
                                    updateTechnicianTimeSlotProvider(
                                      params,
                                    ).future,
                                  );

                                  if (mounted) {
                                    Navigator.pop(context, true);
                                  }
                                } catch (e) {
                                  debugPrint("ERROR: $e");
                                }
                              }
                            : null, // 🔥 null = disabled
                        text: "บันทึก",
                        padding: EdgeInsetsGeometry.symmetric(vertical: 8),
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
                :  AppColors.colorStroke,
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

