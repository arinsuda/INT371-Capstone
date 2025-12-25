import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/core/button/tertiary_button.dart';

import '../../../../../../state/bottom_nav_provider.dart';
import '../../../../../../state/user_provider.dart';
import 'package:changsure/state/activity_editor_state.dart';
import 'components/activity_category_dropdown.dart';

class EditActivityPage extends ConsumerWidget {
  final int id;

  const EditActivityPage({super.key, required this.id});

  void _navigateToView(WidgetRef ref) {
    ref.read(bottomSubPageProvider.notifier).state = const SubPageConfig(
      page: BottomSubPage.technicianViewActivity,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activityEditorProvider(id));
    final notifier = ref.read(activityEditorProvider(id).notifier);

    final user = ref.watch(userProvider);
    final techProfile = user?.technicianProfile;

    if (state.isLoading && state.currentDescription.isEmpty && id > 0) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(
              header: id > 0 ? "แก้ไขผลงาน" : "ลงผลงานใหม่",
              onPressed: () => _navigateToView(ref),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (techProfile?.avatarUrl != null &&
                            techProfile!.avatarUrl!.isNotEmpty)
                        ? NetworkImage(techProfile.avatarUrl!) as ImageProvider
                        : const AssetImage('assets/image/Technician.png'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${techProfile?.firstName ?? ''} ${techProfile?.lastName ?? ''}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

                        ActivityCategoryDropdown(activityId: id),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: state.descriptionError != null
                            ? AppColors.colorError
                            : AppColors.colorStroke,
                        width: state.descriptionError != null ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: notifier.descriptionController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "กรอกคำอธิบายผลงาน...",
                      ),
                    ),
                  ),
                  if (state.descriptionError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        state.descriptionError!,
                        style: const TextStyle(
                          color: AppColors.colorError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...state.assetImages.asMap().entries.map((entry) {
                        return _buildImageItem(
                          Image.network(
                            entry.value,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey,
                              width: 70,
                              height: 70,
                            ),
                          ),
                          () => notifier.removeAssetImage(entry.key),
                        );
                      }),

                      ...state.pickedImages.asMap().entries.map((entry) {
                        return _buildImageItem(
                          Image.file(
                            entry.value,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                          () => notifier.removePickedImage(entry.key),
                        );
                      }),

                      GestureDetector(
                        onTap: notifier.pickImage,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: state.imageError != null
                                  ? AppColors.colorError
                                  : AppColors.primaryBorder,
                              width: state.imageError != null ? 1.5 : 1,
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            color: state.imageError != null
                                ? AppColors.colorError
                                : AppColors.primaryBorder,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.imageError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(
                        state.imageError!,
                        style: const TextStyle(
                          color: AppColors.colorError,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TertiaryButton(
                      text: "ยกเลิก",
                      onPressed: () => _navigateToView(ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: state.isLoading ? "กำลังบันทึก..." : "บันทึก",

                      onPressed:
                          (state.isChanged &&
                              !state.hasError &&
                              !state.isLoading)
                          ? () async {
                              final success = await notifier.savePost();
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      id > 0
                                          ? 'แก้ไขสำเร็จ'
                                          : 'สร้างผลงานสำเร็จ',
                                    ),
                                  ),
                                );
                                _navigateToView(ref);
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('เกิดข้อผิดพลาดในการบันทึก'),
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(Widget imageWidget, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(12), child: imageWidget),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
