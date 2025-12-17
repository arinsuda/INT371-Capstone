import 'package:changsure/state/bottom_nav_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/theme.dart';
import 'activity_section.dart';
import 'technician_badge.dart';
import 'service.dart';

import '../../../../state/user_provider.dart';

class ViewProfileContent extends ConsumerStatefulWidget {
  const ViewProfileContent({super.key});

  @override
  ConsumerState<ViewProfileContent> createState() => _ViewProfileContentState();
}

class _ViewProfileContentState extends ConsumerState<ViewProfileContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final tech = user?.technicianProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            ref.read(bottomSubPageProvider.notifier).state = null;
          },
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await ref.read(userProvider.notifier).refreshUser();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              (tech?.avatarUrl != null &&
                                  tech!.avatarUrl!.isNotEmpty)
                              ? NetworkImage(tech.avatarUrl!) as ImageProvider
                              : const AssetImage('assets/image/Technician.png'),

                          onBackgroundImageError: (exception, stackTrace) {},
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            padding: const EdgeInsets.all(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tech?.fullName ?? 'ไม่ระบุชื่อ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (tech?.isVerified == true)
                            Image.asset(
                              'assets/icons/verify.png',
                              width: 24,
                              height: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.email,
                            size: 14,
                            color: Color(0xFF9B9B9B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tech?.email ?? '-',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF545454),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.phone,
                            size: 14,
                            color: Color(0xFF9B9B9B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tech?.phone ?? '-',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF545454),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/icons/bag_work.svg',
                            width: 14,
                            height: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'จำนวนงานที่รับ: ${tech?.totalJobs ?? 0}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TechnicianBadge(),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "เกี่ยวกับ",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      tech?.bio ?? "ไม่มีข้อมูลสังเขป",
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.colorTertiaryText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ServiceTag(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            ActivitySection(),
          ],
        ),
      ),
    );
  }
}
