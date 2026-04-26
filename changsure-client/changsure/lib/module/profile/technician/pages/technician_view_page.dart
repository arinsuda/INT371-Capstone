import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/core/header.dart';
import 'package:changsure/core/theme.dart';
import '../widgets/technician_content.dart';
import '../widgets/review_tab_widget.dart';
import '../../../../state/user_provider.dart';

class TechnicianProfilePage extends ConsumerWidget {
  final bool isOwner;
  final int? technicianId;

  const TechnicianProfilePage({
    super.key,
    required this.isOwner,
    this.technicianId,
  }) : assert(
         isOwner || technicianId != null,
         'technicianId is required when isOwner is false',
       );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final resolvedTechnicianId = isOwner ? user?.id : technicianId!;

    if (resolvedTechnicianId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!isOwner) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Header(
                    header: "ดูโปรไฟล์",
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    children: [
                      TechnicianContentWidget(
                        isOwner: false,
                        technicianId: technicianId,
                      ),
                      ReviewContent(technicianId: resolvedTechnicianId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  children: [
                    TechnicianContentWidget(isOwner: true),
                    ReviewContent(technicianId: resolvedTechnicianId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return const TabBar(
      labelColor: AppColors.primary,
      unselectedLabelColor: Color(0xFF9B9B9B),
      indicatorColor: AppColors.primary,
      tabs: [
        Tab(text: "โปรไฟล์ช่าง"),
        Tab(text: "รีวิวช่าง"),
      ],
    );
  }
}
