import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/header.dart';
import 'package:changsure/state/bottom_nav_provider.dart';
import 'package:changsure/state/public_technician_provider.dart';

import '../widgets/public_activity_detail_header.dart';
import '../../owner/activities/widgets/activity_image_gallery.dart';

class PublicActivityDetailPage extends ConsumerWidget {
  final int postId;
  final int technicianId;

  const PublicActivityDetailPage({
    super.key,
    required this.postId,
    required this.technicianId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicTechnicianProvider(technicianId));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('เกิดข้อผิดพลาด'),
                const SizedBox(height: 8),
                Text('$e', style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('กลับ'),
                ),
              ],
            ),
          ),
          data: (profile) {
            if (profile == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ไม่พบข้อมูลโปรไฟล์'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('กลับ'),
                    ),
                  ],
                ),
              );
            }

            // หา post จาก profile.posts โดยตรง
            final activity = profile.posts.cast().firstWhere(
              (post) => post.id == postId,
              orElse: () => null,
            );

            if (activity == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ไม่พบข้อมูลผลงาน'),
                    const SizedBox(height: 8),
                    Text(
                      'postId: $postId',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('กลับ'),
                    ),
                  ],
                ),
              );
            }

            // ✅ สร้าง List<String> สำหรับ images
            final imageUrls = <String>[];
            for (var img in activity.images) {
              imageUrls.add(img.imageUrl);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(
                    header: "ดูผลงาน",
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),

                  PublicActivityDetailHeader(
                    post: activity,
                    technicianId: technicianId,
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

                  ActivityImageGallery(
                    images: imageUrls, // ✅ ส่ง List<String> โดยตรง
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
