import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/header.dart';
import 'package:changsure/data/models/technician/post_model.dart';
import 'package:changsure/data/services/technician_service.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:changsure/state/bottom_nav_provider.dart';

import '../widgets/activity_detail_header.dart';
import '../widgets/activity_image_gallery.dart';
import '../widgets/delete_confirmation_dialog.dart';

final activityDetailProvider = FutureProvider.autoDispose
    .family<PostModel?, int>((ref, postId) async {
      final user = ref.read(userProvider);
      if (user?.token == null) return null;

      final service = TechnicianService();
      return service.getPostById(
        token: user!.token!,
        technicianId: user.id,
        postId: postId,
      );
    });

class ActivityDetailPage extends ConsumerWidget {
  final int postId;
  final bool isOwner;
  final int? technicianId;

  const ActivityDetailPage({
    super.key,
    required this.postId,
    this.isOwner = true,
    this.technicianId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityDetailProvider(postId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('เกิดข้อผิดพลาด: $error')),
        data: (activity) {
          if (activity == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ไม่พบข้อมูลผลงาน'),
                  const SizedBox(height: 16),
                  if (!isOwner)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('กลับ'),
                    ),
                ],
              ),
            );
          }

          final imageUrls = activity.images.map((img) => img.imageUrl).toList();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(
                    header: "ดูผลงาน",
                    onPressed: () =>
                        isOwner ? _navigateBack(ref) : Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),

                  ActivityDetailHeader(
                    post: activity,
                    isOwner: isOwner,
                    technicianId: isOwner ? null : technicianId,
                    onEdit: isOwner ? () => _navigateToEdit(ref) : null,
                    onDelete: isOwner
                        ? () => _showDeleteDialog(context, ref)
                        : null,
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      activity.description ?? 'ไม่มีรายละเอียด',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ActivityImageGallery(images: imageUrls),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateBack(WidgetRef ref) {
    ref.read(bottomSubPageProvider.notifier).state = const SubPageConfig(
      page: BottomSubPage.technicianViewActivity,
    );
  }

  void _navigateToEdit(WidgetRef ref) {
    ref.read(bottomSubPageProvider.notifier).state = SubPageConfig(
      page: BottomSubPage.technicianEditActivity,
      activityId: postId,
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    DeleteConfirmationDialog.show(
      context: context,
      onConfirm: () => _handleDelete(context, ref),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();

    final user = ref.read(userProvider);
    if (user?.token == null) return;

    final service = TechnicianService();
    final success = await service.deletePost(
      token: user!.token!,
      technicianId: user.id,
      postId: postId,
    );

    if (!context.mounted) return;

    if (success) {
      _navigateBack(ref);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบผลงานไม่สำเร็จ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
