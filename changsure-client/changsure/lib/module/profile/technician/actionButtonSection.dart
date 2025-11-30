import 'package:changsure/module/profile/technician/activities/postActivity.dart';
import 'package:changsure/module/profile/technician/addressPage.dart';
import 'package:changsure/module/profile/technician/viewActivities.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../state/bottomBarState.dart';
import 'viewProfileTab.dart';

class ActionButtonSection extends StatelessWidget {
  const ActionButtonSection({super.key});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      {
        'label': 'ที่อยู่ของฉัน',
        'icon': Icons.location_on,
        'page': const AddressPage(),
      },
      {
        'label': 'ดูโปรไฟล์ช่าง',
        'icon': 'assets/icons/technicianIcon.png',
        'page': const ViewProfilePage(),
      },
      {
        'label': 'ลงผลงาน',
        'icon': 'assets/icons/postWork.png',
        'page': const ViewActivities(),
      },
      {
        'label': 'ปฏิทินช่าง',
        'icon': 'assets/icons/calendar.png',
        'page': null, // ยังไม่มีหน้านี้
      },
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
              final page = button['page'] as Widget?;
              if (page != null) {
                // ใช้ Navigator.push แทน setSubPage
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => page),
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
                SizedBox(
                  width: 70,
                  child: Text(
                    button['label'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF737373),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
