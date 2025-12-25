import 'package:changsure/core/theme.dart';
import 'package:changsure/module/home/view_service_list.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/module/home/homePage/service_card.dart';
import 'package:changsure/module/home/homePage/banner.dart';
import '../../state/master_data_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String searchQuery = '';
  int? selectedProvinceId = 1;

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value.trim();
    });
  }

  void _onProvinceChanged(int id) {
    setState(() {
      selectedProvinceId = id;
    });
  }

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

  List servicesFromCategories(List categories) {
    return categories
        .expand((c) => c.services)
        .where(
          (s) => s.serName.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final serviceCategoriesAsync = ref.watch(serviceCategoriesProvider);
    print(selectedProvinceId);


    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              HomeBanner(
                onSearchChanged: _onSearchChanged,
                onProvinceChanged: _onProvinceChanged,
              ),

              if (searchQuery.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  builder: (_) => ServiceCategoryPage(
                                    category: category,
                                    provinceId: selectedProvinceId,
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
                                const SizedBox(height: 16),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: serviceCategoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (categories) {
                    /// ====== 🔍 กำลัง search ======
                    if (searchQuery.isNotEmpty) {
                      final services = servicesFromCategories(categories);

                      if (services.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('ไม่พบบริการที่ค้นหา')),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: services.map((service) {
                            return SizedBox(
                              width:
                                  (MediaQuery.of(context).size.width / 2) - 20,
                              height: 220,
                              child: ServiceCard(
                                data: service,
                                provinceId: selectedProvinceId,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }

                    /// ====== 🏠 โหมดปกติ (UI เดิมเป๊ะ) ======
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
                                          provinceId: selectedProvinceId,
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
                                          child: ServiceCard(
                                            data: item,
                                            provinceId: selectedProvinceId,
                                          ),
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
