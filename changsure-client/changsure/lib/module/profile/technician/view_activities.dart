import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/profile/technician_card.dart';
import '../../../core/theme.dart';
import '../../../state/bottom_nav_provider.dart';
import '../../../state/post_provider.dart';

class ViewActivities extends ConsumerStatefulWidget {
  const ViewActivities({super.key});

  @override
  ConsumerState<ViewActivities> createState() => _ViewActivitiesState();
}

class _ViewActivitiesState extends ConsumerState<ViewActivities> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(technicianPostsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(header: "ลงผลงาน"),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _isPressed = true),
                  onTapUp: (_) {
                    setState(() => _isPressed = false);
                    ref
                        .read(bottomSubPageProvider.notifier)
                        .state = const SubPageConfig(
                      page: BottomSubPage.technicianPostActivity,
                    );
                  },
                  onTapCancel: () => setState(() => _isPressed = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: _isPressed
                            ? [
                                AppColors.secondary.withOpacity(0.8),
                                AppColors.secondary,
                              ]
                            : [
                                AppColors.primary.withOpacity(0.8),
                                AppColors.primary,
                              ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/addActivityIcon.svg',
                          height: 16,
                          width: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "เพิ่มผลงาน",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            postsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 50),
                child: Center(child: CircularProgressIndicator()),
              ),

              error: (err, stack) => Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Center(child: Text('Error: $err')),
              ),

              data: (posts) {
                if (posts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(child: Text("คุณยังไม่ได้ลงผลงานใดๆ")),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(6),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 12,

                          childAspectRatio: 0.85,
                        ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final activity = posts[index];

                      return TechnicianCard(
                        id: activity.id,
                        serviceCategoryName: activity.categoryName,
                        description: activity.content,
                        images: activity.images,
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
