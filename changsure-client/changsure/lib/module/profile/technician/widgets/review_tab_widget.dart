import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme.dart';
import '../../../../state/master_data_provider.dart';
import '../../../../state/post_provider.dart';
import '../../../../state/user_provider.dart';

class ReviewContent extends ConsumerStatefulWidget {
  const ReviewContent({super.key});

  @override
  ConsumerState<ReviewContent> createState() => _ReviewContentState();
}

class _ReviewContentState extends ConsumerState<ReviewContent> {
  int? selectedStar;
  bool hasImage = false;
  String? selectedJobType;

  final List<String> jobTypes = [
    "ช่างทาสี",
    "ช่างประปา",
    "ช่างไฟฟ้า",
    "ช่างเครื่องใช้ไฟฟ้า",
  ];

  Widget buildFilterBar() {
    Widget chip({
      required Widget child,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEDF9FF) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.colorStroke,
            ),
          ),
          child: child,
        ),
      );
    }

    return Wrap(
      spacing: 8, // ระยะห่างแนวนอน
      runSpacing: 8, // ระยะห่างแนวตั้ง (ตอนขึ้นบรรทัดใหม่)
      children: [
        // 📷
        chip(
          selected: hasImage,
          onTap: () {
            setState(() {
              hasImage = !hasImage;
              if (hasImage) selectedStar = null;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt,
                size: 18,
                color: hasImage ? AppColors.primary : AppColors.primaryText,
              ),
              const SizedBox(width: 6),
              Text(
                "มีรูปภาพ",
                style: TextStyle(
                  color: hasImage ? AppColors.primary : AppColors.primaryText,
                ),
              ),
            ],
          ),
        ),

        // ⭐
        ...[5, 4, 3, 2, 1].map((star) {
          final isSelected = selectedStar == star;

          return chip(
            selected: isSelected,
            onTap: () {
              setState(() {
                selectedStar = isSelected ? null : star;
                if (selectedStar != null) hasImage = false;
              });
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: isSelected ? AppColors.primary : Color(0xFFFFC53D),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  "$star",
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.primaryText,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
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
            value: selectedCategoryId ?? null,
            hint: const Text(
              "ประเภทงาน",
              style: TextStyle(color: AppColors.primary),
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: -1, // ใช้ -1 แทน null
                child: Text("ทั้งหมด", style: TextStyle(color: Color(0xFF737373)) ),
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
              const Text("ประเภทงาน", style: TextStyle(color: AppColors.primary)),
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
    final user = ref.watch(userProvider);
    final categoriesAsync = ref.watch(serviceCategoriesProvider);
    final selectedCategoryId = ref.watch(selectedCategoryFilterProvider);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final reviewsAsync = ref.watch(technicianReviewsProvider(user.id));

    return reviewsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),

      error: (err, stack) => Center(child: Text('Error: $err')),

      data: (response) {
        final allReviews = response.data.reviews;

        final filteredReviews = allReviews.where((review) {
          // ⭐ filter ดาว
          if (selectedStar != null && review.rating != selectedStar) {
            return false;
          }

          // 📷 filter รูป
          if (hasImage) {
            if (review.images == null || review.images!.isEmpty) {
              return false;
            }
          }

          // 🧰 filter ประเภทงาน (category)
          if (selectedCategoryId != null && selectedCategoryId != -1 &&
              review.service.categoryId != selectedCategoryId) {
            return false;
          }

          return true;
        }).toList();
        final summary = response.data.summary;

        final Map<int, int> ratingCount = {
          1: summary.breakdown["1"] ?? 0,
          2: summary.breakdown["2"] ?? 0,
          3: summary.breakdown["3"] ?? 0,
          4: summary.breakdown["4"] ?? 0,
          5: summary.breakdown["5"] ?? 0,
        };

        final total = summary.totalReviews;
        final avg = summary.avgRating.toDouble();

        // 🔥 ไม่มีรีวิว
        if (allReviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset("assets/image/noReview.png", width: 230),
                const SizedBox(height: 20),
                const Text(
                  "ยังไม่มีรีวิวในขณะนี้",
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        // 🔥 มีรีวิว
        return ListView(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐ LEFT: rating bars
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: List.generate(5, (index) {
                        int star = 5 - index;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RatingBarRow(
                            star: star,
                            count: ratingCount[star]!,
                            total: total,
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ⭐ RIGHT: avg + stars + total
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          avg.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: List.generate(5, (i) {
                            if (i < avg.floor()) {
                              return const Icon(
                                Icons.star_rounded,
                                color: Color(0xFFFFC53D),
                                size: 18,
                              );
                            } else if (i < avg) {
                              return const Icon(
                                Icons.star_half_rounded,
                                color: Color(0xFFFFC53D),
                                size: 18,
                              );
                            } else {
                              return const Icon(
                                Icons.star_border_rounded,
                                color: Color(0xFFFFC53D),
                                size: 18,
                              );
                            }
                          }),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '$total รีวิว',
                          style: const TextStyle(color: AppColors.primaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCategoryDropdownById(
                  categoriesAsync,
                  selectedCategoryId,
                  ref,
                ),
              ],
            ),
            SizedBox(height: 24),
            buildFilterBar(),
            SizedBox(height: 24),
            if (filteredReviews.isEmpty)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset("assets/image/noReview.png", width: 230),
                    const SizedBox(height: 20),
                    const Text(
                      "ยังไม่มีรีวิวในขณะนี้",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredReviews.map((review) {
                final formattedDate = DateFormat(
                  'dd/MM/yy',
                ).format(review.createdAt);
                return Container(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 header (ชื่อ + ดาว)
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: review.customer.avatar != null
                                ? NetworkImage(review.customer.avatar)
                                : null,
                            child: review.customer.avatar == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 8),

                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.customer.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Row(
                                  children: [
                                    // ⭐ stars
                                    ...List.generate(5, (i) {
                                      return Icon(
                                        i < review.rating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 16,
                                        color: const Color(0xFFFFC53D),
                                      );
                                    }),

                                    const SizedBox(width: 8),

                                    // 📅 date
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 📷 images
                      if (review.images != null && review.images!.isNotEmpty)
                        SizedBox(
                          height: 70,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: review.images!.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final img =
                                  review.images![index].imageUrl; // 🔥 สำคัญ

                              return ClipRRect(
                                child: Image.network(
                                  img,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),

                      // 📝 comment
                      if (review.comment != null && review.comment!.isNotEmpty)
                        Text(
                          review.comment!,
                          style: const TextStyle(color: AppColors.primaryText),
                        ),

                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBGHover,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                review.service.picture,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.service.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  review.service.price,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Divider(color: AppColors.colorStroke),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class RatingBarRow extends StatelessWidget {
  final int star;
  final int count;
  final int total;

  const RatingBarRow({
    super.key,
    required this.star,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : count / total;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$star'),
        const SizedBox(width: 8),
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFC53D)),
        const SizedBox(width: 8),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;

              // 🔥 เผื่อที่ให้ count (ประมาณ 30px)
              const countSpace = 20.0;

              final barWidth = count > 0
                  ? (maxWidth - countSpace) * percent
                  : maxWidth * percent;

              return Row(
                children: [
                  // bar
                  Container(
                    width: barWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // count
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: countSpace - 6, // กัน overflow
                      child: Text(
                        "$count",
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.colorTertiaryText,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
