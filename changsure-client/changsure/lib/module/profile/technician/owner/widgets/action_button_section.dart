import 'package:changsure/module/home/booking/section/address_list.dart';
import 'package:changsure/module/profile/technician/owner/calendar/calendar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../state/bottom_nav_provider.dart';

class ActionButtonSection extends ConsumerWidget {
  const ActionButtonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buttons = [
      {'label': 'ที่อยู่ของฉัน', 'icon': Icons.location_on}, // IconData
      {
        'label': 'ดูโปรไฟล์ช่าง',
        'icon': 'assets/icons/technicianIcon.png',
      }, // Asset
      {'label': 'ลงผลงาน', 'icon': 'assets/icons/postWork.png'}, // Asset
      {'label': 'ปฏิทินช่าง', 'icon': 'assets/icons/calendar.png'}, // Asset
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttons.map((button) {
          final icon = button['icon'];

          Widget iconWidget;
          if (icon is IconData) {
            iconWidget = Icon(icon, color: Colors.black, size: 24);
          } else if (icon is String) {
            iconWidget = Image.asset(
              icon,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            );
          } else {
            iconWidget = const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: () {
              // ตรวจสอบปุ่ม "ดูโปรไฟล์ช่าง"
              if (button['label'] == 'ดูโปรไฟล์ช่าง') {
                const config = SubPageConfig(
                  page: BottomSubPage.technicianViewProfile,
                );
                ref.read(bottomSubPageProvider.notifier).state = config;
              }
              if (button['label'] == 'ลงผลงาน') {
                const config = SubPageConfig(
                  page: BottomSubPage.technicianViewActivity,
                );
                ref.read(bottomSubPageProvider.notifier).state = config;
              }
              if (button['label'] == 'ที่อยู่ของฉัน') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddressList(provinceId: null),
                  ),
                );
              }
              if (button['label'] == 'ปฏิทินช่าง') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CalendarPage()),
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: iconWidget),
                ),
                const SizedBox(height: 8),
                Text(
                  button['label'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF737373),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
