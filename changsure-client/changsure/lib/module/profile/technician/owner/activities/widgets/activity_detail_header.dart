// changsure/lib/module/profile/technician/activities/widgets/activity_detail_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/data/models/technician/post_model.dart';
import 'package:changsure/state/user_provider.dart';

import '../shared/constants/activity_constants.dart';
import 'activity_category_badge.dart';
import 'activity_action_menu.dart';

/// Profile header for activity detail page (with actions)
class ActivityDetailHeader extends ConsumerWidget {
  final PostModel post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ActivityDetailHeader({
    super.key,
    required this.post,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final userProfile = user?.technicianProfile;

    final categoryColors = ActivityConstants.getColors(post.categoryName);

    // Get avatar image
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
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundImage: avatarImage,
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 16),

          // Name and Category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile?.fullName ?? 'ไม่ระบุชื่อ',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                ActivityCategoryBadge(
                  label: post.categoryName,
                  colors: categoryColors,
                ),
              ],
            ),
          ),

          // Action Menu
          ActivityActionMenu(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}
