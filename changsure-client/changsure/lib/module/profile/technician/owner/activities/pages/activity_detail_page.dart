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
    .family<PostModel?, int>((ref, id) async {
      final user = ref.read(userProvider);
      if (user?.token == null) return null;

      final service = TechnicianService();
      return service.getPostById(
        token: user!.token!,
        technicianId: user.id,
        postId: id,
      );
    });

class ActivityDetailPage extends ConsumerWidget {
  final int id;

  const ActivityDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityDetailProvider(id));

    return Scaffold(
      backgroundColor: Colors.white,
      body: activityAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text('เกิดข้อผิดพลาด: $error')),
        data: (activity) {
          if (activity == null) {
            return const Center(child: Text('ไม่พบข้อมูลผลงาน'));
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(
                    header: "ดูผลงาน",
                    onPressed: () => _navigateBack(ref),
                  ),
                  const SizedBox(height: 16),

                  ActivityDetailHeader(
                    post: activity,
                    onEdit: () => _navigateToEdit(ref),
                    onDelete: () => _showDeleteDialog(context, ref),
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      activity.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  ActivityImageGallery(images: activity.images),
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
      activityId: id,
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
      postId: id,
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
