import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/button/tertiary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:changsure/module/profile/technician/view_activities.dart'; // เช็ค path
import 'package:changsure/state/bottom_nav_provider.dart';

// Components imports
import 'package:changsure/state/post_activity_state.dart';
import 'components/post_activity_profile_header.dart';
import 'components/post_activity_text_area.dart';
import 'components/post_activity_image_uploader.dart';

class PostActivityPage extends ConsumerWidget {
  const PostActivityPage({super.key});

  void _navigateToViewActivities(WidgetRef ref) {
    // ใช้ bottomSubPageProvider เพื่อเปลี่ยนหน้า
    // (ตัวอย่างใช้ const ViewActivities() ตามโค้ดเดิมของคุณ
    // แต่ถ้าใน system จริงอาจจะต้องใช้ Enum Config เหมือนตอน Edit)

    // แบบที่ 1: ถ้า ViewActivities เป็น SubPageWidget
    // ref.read(bottomSubPageProvider.notifier).state = const SubPageConfig(page: BottomSubPage.viewActivities);

    // แบบที่ 2: ตามโค้ดเดิมของคุณที่ส่ง Widget โดยตรง (ถ้ายังใช้ระบบเดิมอยู่)
    // แต่แนะนำให้ใช้ระบบ Riverpod เต็มรูปแบบคือเปลี่ยน state ของ bottomSubPageProvider ครับ
    // สมมติว่า ViewActivities คือหน้าหลักของ Tab ก็อาจจะแค่ clear subPage
    ref.read(bottomSubPageProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch State เพื่อดูว่า Form Valid หรือยัง
    final isFormValid = ref.watch(
      postActivityProvider.select((s) => s.isFormValid),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            // 1. Header
            Header(
              header: "เพิ่มผลงาน",
              onPressed: () => _navigateToViewActivities(ref),
            ),

            const SizedBox(height: 16),

            // 2. Profile Header
            const PostActivityProfileHeader(),

            const SizedBox(height: 20),

            // 3. Text Area
            const PostActivityTextArea(),

            const SizedBox(height: 20),

            // 4. Image Uploader
            const PostActivityImageUploader(),

            const SizedBox(height: 20),

            // 5. Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Row(
                children: [
                  Expanded(
                    child: TertiaryButton(
                      text: "ยกเลิก",
                      onPressed: () => _navigateToViewActivities(ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: "บันทึก",
                      // Enable ปุ่มเมื่อ Form Valid
                      onPressed: isFormValid
                          ? () {
                              // TODO: Call API to create activity
                              _navigateToViewActivities(ref);
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
