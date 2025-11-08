import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RecommendedServiceSection extends StatelessWidget {
  const RecommendedServiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'จัดการบัญชี', 'icon': Icons.settings_outlined},
      {'label': 'ติดต่อเรา / ศูนย์ช่วยเหลือ', 'icon': Icons.support_agent},
      {'label': 'นโยบายความเป็นส่วนตัว', 'icon': Icons.assignment_outlined},
      {'label': 'ข้อกำหนด', 'icon': Icons.privacy_tip_outlined},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ section
          const Text(
            'บริการแนะนำ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // รายการแนวตั้ง
          Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length ;

              return Column(
                children: [
                  // แถวไอเท็ม
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: const Color(0xFF737373),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item['label'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Color(0xFFAAAAAA),
                          size: 24,
                        ),
                      ],
                    ),
                  ),

                  // เส้นแบ่ง (เว้นอันสุดท้ายไม่ต้องมี)
                  if (!isLast)
                    const Divider(
                      color: Color(0xFFF2F2F2),
                      thickness: 1,
                      height: 1,
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
