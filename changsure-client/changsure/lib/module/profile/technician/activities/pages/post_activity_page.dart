import 'package:changsure/module/profile/technician/activities/shared/widgets/activirt_text_area.dart';
import 'package:changsure/module/profile/technician/activities/shared/widgets/activity_image_uploader.dart';
import 'package:changsure/module/profile/technician/activities/shared/widgets/activity_profile_header.dart';
import 'package:changsure/state/post_provider.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/button/tertiary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:changsure/state/bottom_nav_provider.dart';

import 'package:changsure/state/activity_editor_state.dart';

class PostActivityPage extends ConsumerWidget {
  const PostActivityPage({super.key});

  void _navigateToViewActivities(WidgetRef ref) {
    ref.read(bottomSubPageProvider.notifier).state = const SubPageConfig(
      page: BottomSubPage.technicianViewActivity,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = activityEditorProvider(0);
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final user = ref.watch(userProvider);

    final isFormValid =
        state.currentDescription.isNotEmpty &&
        state.categoryId != null &&
        (state.pickedImages.isNotEmpty || state.assetImages.isNotEmpty);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(
              header: "เพิ่มผลงาน",
              onPressed: () => _navigateToViewActivities(ref),
            ),

            const SizedBox(height: 16),

            const ActivityProfileHeader(activityId: 0),

            const SizedBox(height: 20),

            const ActivityTextArea(activityId: 0),

            const SizedBox(height: 20),

            const ActivityImageUploader(activityId: 0),

            const SizedBox(height: 20),

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
                      text: state.isLoading ? "กำลังบันทึก..." : "บันทึก",

                      onPressed: (isFormValid && !state.isLoading)
                          ? () async {
                              final success = await notifier.savePost();

                              if (context.mounted) {
                                if (success) {
                                  ref.invalidate(myPostsProvider);
                                  if (user != null) {
                                    ref.invalidate(
                                      technicianPostsProvider(
                                        PostsParams(technicianId: user.id),
                                      ),
                                    );
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('สร้างผลงานสำเร็จ'),
                                    ),
                                  );
                                  _navigateToViewActivities(ref);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'เกิดข้อผิดพลาด กรุณาตรวจสอบข้อมูล',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
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
