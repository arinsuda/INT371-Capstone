import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/core/button/tertiary_button.dart';

import 'package:changsure/data/models/technician/post_model.dart';
import 'package:changsure/data/services/technician_service.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:changsure/state/bottom_nav_provider.dart';

const Map<String, Map<String, Color>> kActivityColorMap = {
  "งานทาสี": {
    "text": Color(0xFFEB2F96),
    "background": Color(0xFFFFF0F6),
    "border": Color(0xFFFFADD2),
  },
  "งานประปา": {
    "text": Color(0xFF36CFC9),
    "background": Color(0xFFE6FFFB),
    "border": Color(0xFF87E8DE),
  },
  "งานไฟฟ้า": {
    "text": Color(0xFFFAAD14),
    "background": Color(0xFFFFFBE6),
    "border": Color(0xFFFFE58F),
  },
  "งานซ่อมเครื่องใช้ไฟฟ้า": {
    "text": Color(0xFF722ED1),
    "background": Color(0xFFF9F0FF),
    "border": Color(0xFFD3ADF7),
  },
};

final postDetailProvider = FutureProvider.autoDispose.family<PostModel?, int>((
  ref,
  id,
) async {
  final user = ref.read(userProvider);
  if (user?.token == null) return null;

  final service = TechnicianService();
  return service.getPostById(user!.token!, id);
});

class ViewActivityById extends ConsumerWidget {
  final int id;

  const ViewActivityById({super.key, required this.id});

  void _navigateBack(WidgetRef ref) {
    ref.read(bottomSubPageProvider.notifier).state = const SubPageConfig(
      page: BottomSubPage.technicianViewActivity,
    );
  }

  void _navigateToEdit(WidgetRef ref) {
    final config = SubPageConfig(
      page: BottomSubPage.technicianEditActivity,
      activityId: id,
    );
    ref.read(bottomSubPageProvider.notifier).state = config;
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();

    final user = ref.read(userProvider);
    final service = TechnicianService();

    final success = await service.deletePost(token: user!.token!, postId: id);

    if (success && context.mounted) {
      _navigateBack(ref);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบโพสต์ไม่สำเร็จ')));
    }
  }

  void _showDeleteModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => _DeleteConfirmationDialog(
        onConfirm: () => _handleDelete(context, ref),
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(postDetailProvider(id));

    return Scaffold(
      backgroundColor: Colors.white,
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('เกิดข้อผิดพลาด: $err')),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('ไม่พบข้อมูลโพสต์'));
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

                  _ActivityProfileHeader(
                    post: post,
                    onEdit: () => _navigateToEdit(ref),
                    onDelete: () => _showDeleteModal(context, ref),
                  ),
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _ActivityImageGallery(images: post.images),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityProfileHeader extends ConsumerWidget {
  final PostModel post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActivityProfileHeader({
    required this.post,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor =
        kActivityColorMap[post.categoryName] ?? kActivityColorMap["default"];
    final user = ref.watch(userProvider);
    final userProfile = user?.technicianProfile;

    ImageProvider avatarImage;
    if (userProfile?.avatarUrl != null && userProfile!.avatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(userProfile.avatarUrl!);
    } else {
      avatarImage = const AssetImage('assets/image/Technician.png');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: avatarImage,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile?.fullName ?? 'ไม่ระบุชื่อ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _CategoryBadge(label: post.categoryName, colors: categoryColor),
              ],
            ),
          ),
          _ActionMenuButton(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Map<String, Color>? colors;

  const _CategoryBadge({required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors?["background"] ?? Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors?["border"] ?? Colors.grey),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors?["text"] ?? Colors.black,
        ),
      ),
    );
  }
}

class _ActionMenuButton extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionMenuButton({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      elevation: 4,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: SvgPicture.asset(
        'assets/icons/optionIcon.svg',
        height: 20,
        width: 20,
      ),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        _buildPopupMenuItem('edit', Icons.create_rounded, "แก้ไขโพสต์"),
        _buildPopupMenuItem('delete', Icons.delete, "ลบโพสต์"),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String text,
  ) {
    return PopupMenuItem(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Center(
              child: Icon(icon, size: 20, color: AppColors.colorTertiaryText),
            ),
          ),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}

class _ActivityImageGallery extends StatelessWidget {
  final List<String> images;

  const _ActivityImageGallery({required this.images});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: images.map((imgUrl) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),

              child: Image.network(
                imgUrl,
                width: double.infinity,
                fit: BoxFit.cover,

                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },

                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "ลบผลงาน",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "คุณแน่ใจหรือไม่ว่าต้องการลบผลงานนี้ออกจากหน้าโปรไฟล์ช่างของคุณ? ผลงานดังกล่าวจะถูกลบออกจากโปรไฟล์ของคุณอย่างถาวร",
              style: TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TertiaryButton(
                    text: "ยกเลิก",
                    onPressed: onCancel,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    fontSize: 14,
                    borderRadius: 8,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF5222D)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      foregroundColor: const Color(0xFFF5222D),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: onConfirm,
                    child: const Text(
                      "ลบ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
