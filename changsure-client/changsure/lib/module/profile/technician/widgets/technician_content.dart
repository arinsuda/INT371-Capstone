import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:changsure/core/profile/technician_card.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:changsure/state/master_data_provider.dart';
import 'package:changsure/state/post_provider.dart';

import 'package:changsure/module/profile/technician/activities/shared/constants/activity_constants.dart';
import 'technician_badge.dart';
import 'service_card.dart';

class TechnicianContentWidget extends ConsumerStatefulWidget {
  final bool isOwner;
  final int? technicianId;

  const TechnicianContentWidget({
    super.key,
    required this.isOwner,
    this.technicianId,
  });

  @override
  ConsumerState<TechnicianContentWidget> createState() =>
      _TechnicianContentWidgetState();
}

class _TechnicianContentWidgetState
    extends ConsumerState<TechnicianContentWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildOwnerView() {
    final user = ref.watch(userProvider);
    final tech = user?.technicianProfile;
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);

    final postsState = ref.watch(
      technicianPostsProvider(
        PostsParams(technicianId: user!.id, categoryId: selectedCategoryId),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          await ref.read(userProvider.notifier).refreshUser();
          ref
              .read(
                technicianPostsProvider(
                  PostsParams(
                    technicianId: user.id,
                    categoryId: selectedCategoryId,
                  ),
                ).notifier,
              )
              .refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  _buildAvatar(tech?.avatarUrl, isOwner: true),
                  const SizedBox(height: 10),
                  _buildOwnerNameSection(tech),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TechnicianBadge(),
                  ),
                  const SizedBox(height: 8),
                  _buildSectionTitle("เกี่ยวกับ"),
                  const SizedBox(height: 8),
                  _buildBioText(tech?.bio),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ServiceTag(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "ผลงานช่าง",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildCategoryDropdownById(
                      categoriesAsync,
                      selectedCategoryId,
                      ref,
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: _buildPostsGrid(postsState)),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicView() {
    final id = widget.technicianId!;

    final profileState = ref.watch(technicianProfileProvider(id));

    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);
    final postsState = ref.watch(
      technicianPostsProvider(
        PostsParams(technicianId: id, categoryId: selectedCategoryId),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          ref.read(technicianProfileProvider(id).notifier).refresh();
          ref
              .read(
                technicianPostsProvider(
                  PostsParams(technicianId: id, categoryId: selectedCategoryId),
                ).notifier,
              )
              .refresh();
        },
        child: profileState.when(
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
                      .read(technicianProfileProvider(id).notifier)
                      .refresh(),
                  child: const Text("ลองใหม่"),
                ),
              ),
            ],
          ),
          data: (p) {
            if (p == null) {
              return const Center(child: Text("ไม่พบข้อมูลช่าง"));
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildAvatar(p.avatarUrl, isOwner: false),
                      const SizedBox(height: 10),
                      _buildPublicNameSection(
                        p.fullName.trim(),
                        p.totalJobs,
                        p.isVerified,
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("เกี่ยวกับ"),
                      const SizedBox(height: 8),
                      _buildBioText(p.bio),
                      const SizedBox(height: 16),
                      if (p.services.isNotEmpty) ...[
                        _buildSectionTitle("บริการ"),
                        const SizedBox(height: 8),
                        _buildServiceTags(p.services),
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

                            _buildCategoryDropdownById(
                              categoriesAsync,
                              selectedCategoryId,
                              ref,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SliverToBoxAdapter(
                  child: _buildPostsGrid(
                    postsState,
                    technicianId: id,
                    isPublicView: true,
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

  Widget _buildPostsGrid(
    PostsState postsState, {
    int? technicianId,
    bool isPublicView = false,
  }) {
    if (postsState.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final posts = postsState.posts;

    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text("ไม่มีผลงาน", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return TechnicianCard(
            id: post.id,
            serviceCategoryName: post.categoryName ?? '',
            description: post.description ?? '',
            images: post.images.map((e) => e.imageUrl).toList(),
            technicianId: technicianId,
            isPublicView: isPublicView,
          );
        },
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, {required bool isOwner}) {
    ImageProvider image;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      image = NetworkImage(avatarUrl);
    } else {
      image = const AssetImage('assets/image/Technician.png');
    }

    return Center(
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: image,
        onBackgroundImageError: (_, __) {},
      ),
    );
  }

  Widget _buildOwnerNameSection(dynamic tech) {
    return Column(
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
              Image.asset('assets/icons/verify.png', width: 24, height: 24),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 14, color: Color(0xFF9B9B9B)),
            const SizedBox(width: 4),
            Text(
              tech?.email ?? '-',
              style: const TextStyle(fontSize: 10, color: Color(0xFF545454)),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.phone, size: 14, color: Color(0xFF9B9B9B)),
            const SizedBox(width: 4),
            Text(
              tech?.phone ?? '-',
              style: const TextStyle(fontSize: 10, color: Color(0xFF545454)),
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
              style: const TextStyle(fontSize: 10, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPublicNameSection(
    String fullName,
    int totalJobs,
    bool isVerified,
  ) {
    return Column(
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
              Image.asset('assets/icons/verify.png', width: 24, height: 24),
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
              style: const TextStyle(fontSize: 10, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBioText(String? bio) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        (bio == null || bio.isEmpty) ? "ไม่มีข้อมูลสังเขป" : bio,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.colorTertiaryText,
        ),
      ),
    );
  }

  Widget _buildServiceTags(List services) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: {for (final s in services) (s.categoryName ?? 'อื่นๆ')}.map((
          category,
        ) {
          final colors = ActivityConstants.getColors(category);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border, width: 1),
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
    );
  }

  Widget _buildCategoryDropdownById(
    AsyncValue categoriesAsync,
    int? selectedCategoryId,
    WidgetRef ref,
  ) {
    return categoriesAsync.when(
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => const SizedBox(),
      data: (categories) {
        return DropdownButtonHideUnderline(
          child: DropdownButton2<int?>(
            isExpanded: false,
            value: selectedCategoryId,
            hint: const Text(
              "ทั้งหมด",
              style: TextStyle(color: AppColors.primary),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text(
                  "ทั้งหมด",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
              ...categories.map(
                (cat) => DropdownMenuItem<int>(
                  value: cat.id,
                  child: Text(
                    cat.catName,
                    style: const TextStyle(color: Color(0xFF737373)),
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              ref.read(selectedCategoryFilterProvider.notifier).state = value;
            },
            selectedItemBuilder: (_) => [
              const Text("ทั้งหมด", style: TextStyle(color: AppColors.primary)),
              ...categories.map(
                (e) => Text(
                  e.catName,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
            buttonStyleData: ButtonStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              height: 32,
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
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isOwner ? _buildOwnerView() : _buildPublicView();
  }
}
