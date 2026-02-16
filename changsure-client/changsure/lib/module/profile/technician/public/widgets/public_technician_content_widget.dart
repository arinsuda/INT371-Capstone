import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../core/theme.dart';
import '../../../../../state/public_technician_provider.dart';
import '../../../technician/owner/activities/shared/constants/activity_constants.dart';

import 'package:changsure/core/profile/technician_card.dart';

class PublicTechnicianContent extends ConsumerStatefulWidget {
  final int technicianId;
  const PublicTechnicianContent({super.key, required this.technicianId});

  @override
  ConsumerState<PublicTechnicianContent> createState() =>
      _PublicTechnicianContentState();
}

class _PublicTechnicianContentState
    extends ConsumerState<PublicTechnicianContent> {
  String? _selectedCategoryName;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(
      publicTechnicianProvider(widget.technicianId),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          setState(() {
            _selectedCategoryName = null;
          });
          await ref
              .read(publicTechnicianProvider(widget.technicianId).notifier)
              .loadProfile();
        },
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text(
                  "โหลดโปรไฟล์ไม่สำเร็จ: $e",
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton(
                  onPressed: () => ref
                      .read(
                        publicTechnicianProvider(widget.technicianId).notifier,
                      )
                      .loadProfile(),
                  child: const Text("ลองใหม่"),
                ),
              ),
            ],
          ),
          data: (p) {
            if (p == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child: Text(
                      "ไม่พบข้อมูลช่าง",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            final fullName = "${p.firstName} ${p.lastName}".trim();
            final avatarUrl = p.avatarUrl;
            final totalJobs = p.totalJobs ?? 0;
            final isVerified = p.isVerified == true;
            final bio = (p.bio == null || p.bio!.isEmpty)
                ? "ไม่มีข้อมูลสังเขป"
                : p.bio!;
            final services = p.services ?? const [];
            final allPosts = p.posts ?? const [];

            final Set<String> categoriesSet = allPosts
                .map((post) => post.categoryName ?? 'อื่นๆ')
                .toSet();
            final List<String> categories = categoriesSet.toList();

            final displayedPosts = _selectedCategoryName == null
                ? allPosts
                : allPosts
                      .where(
                        (post) =>
                            (post.categoryName ?? 'อื่นๆ') ==
                            _selectedCategoryName,
                      )
                      .toList();

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  (avatarUrl != null && avatarUrl.isNotEmpty)
                                  ? NetworkImage(avatarUrl)
                                  : const AssetImage(
                                          'assets/image/Technician.png',
                                        )
                                        as ImageProvider,
                              onBackgroundImageError: (_, __) {},
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
                                fullName.isEmpty ? "ไม่ระบุชื่อ" : fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 4),
                              if (isVerified)
                                Image.asset(
                                  'assets/icons/verify.png',
                                  width: 24,
                                  height: 24,
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
                                'จำนวนงานที่รับ: $totalJobs',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

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
                          bio,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.colorTertiaryText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (services.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            "บริการ",
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
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                {
                                  for (final s in services)
                                    (s.categoryName ?? 'อื่นๆ'),
                                }.map((category) {
                                  final colors = ActivityConstants.getColors(
                                    category,
                                  );
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.background,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: colors.border,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "ผลงาน",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            DropdownButtonHideUnderline(
                              child: DropdownButton2<String?>(
                                isExpanded: false,
                                value: _selectedCategoryName,
                                hint: const Text(
                                  "ทั้งหมด",
                                  style: TextStyle(color: AppColors.primary),
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      "ทั้งหมด",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  ...categories.map(
                                    (catName) => DropdownMenuItem<String>(
                                      value: catName,
                                      child: Text(
                                        catName,
                                        style: const TextStyle(
                                          color: Color(0xFF737373),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCategoryName = value;
                                  });
                                },
                                selectedItemBuilder: (context) {
                                  if (_selectedCategoryName == null) {
                                    return [
                                      const Text(
                                        "ทั้งหมด",
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      ...categories.map(
                                        (e) => Text(
                                          e,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ];
                                  }
                                  return [
                                    const Text(
                                      "ทั้งหมด",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    ...categories.map(
                                      (catName) => Text(
                                        catName,
                                        style: const TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ];
                                },
                                buttonStyleData: ButtonStyleData(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 0,
                                    vertical: 6,
                                  ),
                                  height: 32,
                                  width: null,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBGHover,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                dropdownStyleData: DropdownStyleData(
                                  maxHeight: 200,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  offset: const Offset(0, -10),
                                ),
                                menuItemStyleData: const MenuItemStyleData(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                if (displayedPosts.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "ยังไม่มีผลงานในหมวดหมู่นี้",
                        style: TextStyle(color: AppColors.colorTertiaryText),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = displayedPosts[index];

                        return TechnicianCard(
                          id: post.id,
                          serviceCategoryName:
                              post.categoryName ?? 'ไม่ระบุหมวดหมู่',
                          description: post.description ?? 'ไม่มีรายละเอียด',
                          images: post.images
                              .map((img) => img.imageUrl)
                              .toList(),
                          technicianId: widget.technicianId,
                          isPublicView: true,
                        );
                      }, childCount: displayedPosts.length),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}
