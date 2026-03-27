import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/data/models/technician/post_model.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:changsure/state/post_provider.dart';

import '../shared/constants/activity_constants.dart';
import 'activity_category_badge.dart';
import 'activity_action_menu.dart';

class ActivityDetailHeader extends ConsumerWidget {
  final PostModel post;
  final bool isOwner;

  final int? technicianId;

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActivityDetailHeader({
    super.key,
    required this.post,
    this.isOwner = true,
    this.technicianId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? avatarUrl;
    String fullName = 'ไม่ระบุชื่อ';

    if (isOwner) {
      final user = ref.watch(userProvider);
      final profile = user?.technicianProfile;
      avatarUrl = profile?.avatarUrl;
      fullName = profile?.fullName ?? 'ไม่ระบุชื่อ';
    } else if (technicianId != null) {
      final profileState = ref.watch(technicianProfileProvider(technicianId!));
      profileState.whenData((p) {
        if (p != null) {
          avatarUrl = p.avatarUrl;
          fullName = p.fullName;
        }
      });
    }

    ImageProvider avatarImage;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      avatarImage = NetworkImage(avatarUrl!);
    } else {
      avatarImage = const AssetImage('assets/image/Technician.png');
    }

    final categoryColors = ActivityConstants.getColors(post.categoryName);

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
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ActivityCategoryBadge(
                  label: post.categoryName ?? "",
                  colors: categoryColors,
                ),
              ],
            ),
          ),

          if (isOwner && onEdit != null && onDelete != null)
            ActivityActionMenu(onEdit: onEdit!, onDelete: onDelete!),
        ],
      ),
    );
  }
}
