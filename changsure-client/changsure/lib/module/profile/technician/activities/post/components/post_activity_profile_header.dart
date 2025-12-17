import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../state/user_provider.dart';

import '../../edit/components/activity_category_dropdown.dart';

class PostActivityProfileHeader extends ConsumerWidget {
  const PostActivityProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final techProfile = user?.technicianProfile;

    return Padding(
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
                  "${techProfile?.firstName ?? 'ไม่ระบุชื่อ'} ${techProfile?.lastName ?? ''}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                const ActivityCategoryDropdown(activityId: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
