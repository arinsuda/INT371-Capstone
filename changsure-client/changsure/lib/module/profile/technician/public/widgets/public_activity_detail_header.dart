import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/data/models/technician/public_post_model.dart';
import 'package:changsure/state/public_technician_provider.dart';

import '../../owner/activities/shared/constants/activity_constants.dart';
import '../../owner/activities/widgets/activity_category_badge.dart';

class PublicActivityDetailHeader extends ConsumerWidget {
  final PublicPost post;
  final int technicianId;

  const PublicActivityDetailHeader({
    super.key,
    required this.post,
    required this.technicianId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicTechnicianProvider(technicianId));

    final categoryColors = ActivityConstants.getColors(post.categoryName);

    return profileAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();

        ImageProvider avatarImage;
        if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
          avatarImage = NetworkImage(profile.avatarUrl!);
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
                      profile.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ActivityCategoryBadge(
                      label: post.categoryName ?? 'อื่นๆ',
                      colors: categoryColors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
