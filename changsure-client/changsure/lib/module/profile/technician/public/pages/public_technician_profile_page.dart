import 'package:changsure/module/profile/technician/public/widgets/public_technician_content_widget.dart';
import 'package:changsure/module/profile/technician/public/widgets/public_technician_review_tab_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';

import 'package:changsure/state/public_technician_provider.dart';

class PublicTechnicianProfilePage extends ConsumerWidget {
  final int technicianId;

  const PublicTechnicianProfilePage({super.key, required this.technicianId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicTechnicianProvider(technicianId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Header(header: "ดูโปรไฟล์"),
              ),

              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF9B9B9B),
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: "โปรไฟล์ช่าง"),
                  Tab(text: "รีวิวช่าง"),
                ],
              ),

              Expanded(
                child: profileAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorState(
                    message: 'โหลดโปรไฟล์ไม่สำเร็จ',
                    onRetry: () => ref
                        .read(publicTechnicianProvider(technicianId).notifier)
                        .loadProfile(),
                  ),
                  data: (profile) {
                    if (profile == null) {
                      return _ErrorState(
                        message: 'ไม่พบข้อมูลช่าง',
                        onRetry: () => ref
                            .read(
                              publicTechnicianProvider(technicianId).notifier,
                            )
                            .loadProfile(),
                      );
                    }

                    return TabBarView(
                      children: [
                        PublicTechnicianContent(technicianId: technicianId),
                        const PublicTechnicianReviewsTab(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('ลองใหม่')),
          ],
        ),
      ),
    );
  }
}
