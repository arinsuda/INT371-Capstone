import 'package:changsure/core/theme.dart';
import 'package:changsure/module/home/view_service_list.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:provider/provider.dart';

import 'package:changsure/state/category_state.dart';
import '../../state/service_state.dart';
import './homePage/service_card.dart';
import './homePage/banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ServiceCategoryState>().loadCategories();
      context.read<ServiceState>().loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = context.watch<ServiceCategoryState>();
    final serviceState = context.watch<ServiceState>();

    // ===========================
    // Loading
    // ===========================
    if (categoryState.loading || serviceState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ===========================
    // Error Handling
    // ===========================
    if (categoryState.errorMessage != null || serviceState.error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            "เกิดข้อผิดพลาด: \n${categoryState.errorMessage ?? ""}\n${serviceState.error ?? ""}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // ===========================
    // Safe data (ป้องกัน null)
    // ===========================
    final categories = categoryState.categories ?? [];
    final services = serviceState.services ?? [];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const HomeBanner(),

          // ----------------------------
          // Shortcuts / ปุ่มลัดหมวดหมู่
          // ----------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: categories.take(4).map((cat) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServiceCategoryPage(
                          categoryId: cat.id,
                          categoryName: cat.catName,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryBGHover,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child:
                              (cat.iconUrl != null && cat.iconUrl!.isNotEmpty)
                              ? Image.network(
                                  cat.iconUrl!,
                                  width: 30,
                                  height: 30,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.broken_image,
                                    size: 30,
                                    color: Colors.grey,
                                  ),
                                )
                              : const Icon(
                                  Icons.category,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat.catName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF737373),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // ----------------------------
          // แสดงบริการแยกตามหมวด
          // ----------------------------
          ...categories.map((cat) {
            final items = services
                .where((s) => s.categoryId == cat.id)
                .toList();

            if (items.isEmpty) return const SizedBox();

            final showItems = items.take(2).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header หมวดหมู่
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cat.catName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceCategoryPage(
                                categoryId: cat.id,
                                categoryName: cat.catName,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // การ์ดบริการ 2 อัน
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: List.generate(
                      showItems.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            height: 220,
                            child: ServiceCard(data: showItems[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}
