import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/button/tertiary_button.dart';
import 'package:flutter/material.dart';

import '../../../../../../core/theme.dart';

class ManageTodayWorkSheet extends StatefulWidget {
  const ManageTodayWorkSheet({super.key});

  @override
  State<ManageTodayWorkSheet> createState() => _ManageTodayWorkSheetState();
}

class _ManageTodayWorkSheetState extends State<ManageTodayWorkSheet> {
  Set<String> selectedTimes = {"9:00 - 12:00", "13:00 - 16:00"};

  bool isOpen = true;
  bool isDefaultTime = false;

  @override
  Widget build(BuildContext context) {
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

                const Text(
                  "เวลาที่สะดวกรับงาน",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),

                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final time in [
                      "9:00 - 12:00",
                      "13:00 - 16:00",
                      "17:00 - 20:00",
                    ])
                      _TimeChip(
                        text: time,
                        selected: selectedTimes.contains(time),
                        onTap: () {
                          setState(() {
                            if (selectedTimes.contains(time)) {
                              selectedTimes.remove(time);
                            } else {
                              selectedTimes.add(time);
                            }
                          });
                        },
                      ),
                  ],
                ),

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
                      onChanged: (value) {
                        setState(() => isOpen = value);
                      },
                      thumbColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white; // ตอนเปิด
                        }
                        return Colors.white; // ตอนปิด
                      }),
                      trackColor: MaterialStateProperty.resolveWith((states) {
                        if (states.contains(MaterialState.selected)) {
                          return AppColors.primary;
                        }
                        return AppColors.colorStroke; // พื้นในตอนปิด
                      }),
                      trackOutlineColor: MaterialStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.white; // ขอบตอนปิด
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
                        onPressed: () {},
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
  final VoidCallback onTap;

  const _TimeChip({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
          color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? AppColors.primary : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
