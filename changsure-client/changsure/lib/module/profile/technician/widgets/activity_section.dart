import 'package:changsure/state/master_data_provider.dart';
import 'package:changsure/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:changsure/core/profile/technician_card.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/state/post_provider.dart';

class ActivitySection extends ConsumerWidget {
  const ActivitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);
    final user = ref.watch(userProvider);

    final postsState = ref.watch(
      technicianPostsProvider(
        PostsParams(technicianId: user!.id, categoryId: selectedCategoryId),
      ),
    );

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ผลงานช่าง",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              categoriesAsync.when(
                loading: () => const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const SizedBox(),
                data: (categories) {
                  final items = [
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
                  ];

                  return DropdownButtonHideUnderline(
                    child: DropdownButton2<int?>(
                      isExpanded: false,
                      value: selectedCategoryId,
                      hint: const Text(
                        "ทั้งหมด",
                        style: TextStyle(color: AppColors.primary),
                      ),
                      items: items,
                      onChanged: (value) {
                        ref
                                .read(selectedCategoryFilterProvider.notifier)
                                .state =
                            value;
                      },
                      selectedItemBuilder: (context) => [
                        const Text(
                          "ทั้งหมด",
                          style: TextStyle(color: AppColors.primary),
                        ),
                        ...categories.map(
                          (cat) => Text(
                            cat.catName,
                            style: const TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
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
                  );
                },
              ),
            ],
          ),
        ),

        if (postsState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (postsState.posts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text("ไม่มีผลงาน", style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Padding(
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
              itemCount: postsState.posts.length,
              itemBuilder: (context, index) {
                final post = postsState.posts[index];

                return TechnicianCard(
                  id: post.id,
                  serviceCategoryName: post.categoryName ?? '',
                  description: post.description ?? '',
                  images: post.images.map((e) => e.imageUrl).toList(),
                );
              },
            ),
          ),

        const SizedBox(height: 24),
      ]),
    );
  }
}
