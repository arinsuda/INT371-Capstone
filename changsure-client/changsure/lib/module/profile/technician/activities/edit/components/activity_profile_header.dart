import 'package:flutter/material.dart';
import 'activity_category_dropdown.dart';

class ActivityProfileHeader extends StatelessWidget {
  final int activityId;

  const ActivityProfileHeader({super.key, required this.activityId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/image/Technician.png'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "คุณ สมชาย รักชาติ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // เรียกใช้ Dropdown ที่แยกไฟล์ไว้
                ActivityCategoryDropdown(activityId: activityId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
