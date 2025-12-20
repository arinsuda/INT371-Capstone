import 'package:changsure/core/theme.dart';
import 'package:changsure/module/home/view_service_list.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/module/home/homePage/service_card.dart';
import 'package:changsure/module/home/homePage/banner.dart';
import '../../state/master_data_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Widget _buildCategoryIcon(String name) {
    const iconMap = {
      'งานทาสี': 'assets/icons/painted.png',
      'งานประปา': 'assets/icons/waterWork.png',
      'งานไฟฟ้า': 'assets/icons/powerSupply.png',
      'งานเครื่องใช้ไฟฟ้า': 'assets/icons/electric.png',
    };

    final path = iconMap[name];
    if (path == null) {
      return const Icon(Icons.build, size: 30);
    }

    return Image.asset(path, width: 30, height: 30);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceCategoriesAsync = ref.watch(serviceCategoriesProvider);

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              HomeBanner(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: serviceCategoriesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (categories) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: categories.take(4).map((category) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ServiceCategoryPage(category: category),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBGHover,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: _buildCategoryIcon(category.catName),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category.catName,
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
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: serviceCategoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (categories) {
                    return Column(
                      children: categories.map((mainCategory) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Text(
                                    mainCategory.catName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
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
                                          category: mainCategory,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),

                            // การ์ด 2 ใบ
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                children: List.generate(
                                  mainCategory.services.length >= 2
                                      ? 2
                                      : mainCategory.services.length,
                                  (index) {
                                    final item = mainCategory.services[index];
                                    return Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: SizedBox(
                                          height: 220,
                                          child: ServiceCard(data: item),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
