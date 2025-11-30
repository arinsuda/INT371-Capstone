import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class RecommendedServiceSection extends StatelessWidget {
  const RecommendedServiceSection({super.key});

  // ฟังก์ชันแสดง Dialog ติดต่อเรา
  void _showContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ติดต่อเรา'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📞 เบอร์โทร: 02-XXX-XXXX'),
            SizedBox(height: 8),
            Text('📧 อีเมล: support@changsure.com'),
            SizedBox(height: 8),
            Text('⏰ เวลาทำการ: จ-ศ 09:00-18:00'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  // ฟังก์ชันแสดงหน้านโยบาย
  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('นโยบายความเป็นส่วนตัว'),
            backgroundColor: AppColors.primary,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'นโยบายความเป็นส่วนตัว',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'เนื้อหานโยบายความเป็นส่วนตัวของคุณ...',
                  style: TextStyle(fontSize: 14),
                ),
                // เพิ่มเนื้อหาตามต้องการ
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ฟังก์ชันแสดงข้อกำหนด
  void _showTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('ข้อกำหนดและเงื่อนไข'),
            backgroundColor: AppColors.primary,
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อกำหนดและเงื่อนไข',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text(
                  'เนื้อหาข้อกำหนดและเงื่อนไขของคุณ...',
                  style: TextStyle(fontSize: 14),
                ),
                // เพิ่มเนื้อหาตามต้องการ
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'label': 'จัดการบัญชี',
        'icon': Icons.settings_outlined,
        'action': () {
          // นำทางไปหน้าจัดการบัญชี (สามารถสร้างหน้าใหม่ได้)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('กำลังพัฒนาฟีเจอร์นี้')));
        },
      },
      {
        'label': 'ติดต่อเรา / ศูนย์ช่วยเหลือ',
        'icon': Icons.support_agent,
        'action': () => _showContactDialog(context),
      },
      {
        'label': 'นโยบายความเป็นส่วนตัว',
        'icon': Icons.assignment_outlined,
        'action': () => _showPrivacyPolicy(context),
      },
      {
        'label': 'ข้อกำหนด',
        'icon': Icons.privacy_tip_outlined,
        'action': () => _showTerms(context),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'บริการแนะนำ',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isLast = index == items.length - 1;

              return Column(
                children: [
                  // แถวไอเท็ม
                  InkWell(
                    onTap: () {
                      final action = item['action'] as Function?;
                      action?.call();
                    },
                    child: Padding(
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
                  ),

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
