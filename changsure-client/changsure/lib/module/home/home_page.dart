import 'package:changsure/core/theme.dart';
import 'package:changsure/module/home/view_service_list.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:provider/provider.dart';
import '../../mockDB/service_categories.dart';
import '../../state/bottom_bar_state.dart';
import './homePage/service_card.dart';
import './homePage/banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonToCategory = {
      'ทาสี': 'งานทาสี',
      'การประปา': 'งานประปา',
      'การไฟฟ้า': 'งานไฟฟ้า',
      'เครื่องใช้ไฟฟ้า': 'งานซ่อมเครื่องใช้ไฟฟ้า',
    };

    final buttons = [
      {'label': 'ทาสี', 'icon': 'assets/icons/painted.png'},
      {'label': 'การประปา', 'icon': 'assets/icons/waterWork.png'},
      // Asset
      {'label': 'การไฟฟ้า', 'icon': 'assets/icons/powerSupply.png'},
      // Asset
      {'label': 'เครื่องใช้ไฟฟ้า', 'icon': 'assets/icons/electric.png'},
      // Asset
    ];

    return Scaffold(
      body: Stack(
        children: [
          // ListView ที่มี HomeBanner เป็น item แรก
          ListView(
            padding: EdgeInsets.zero,
            children: [
              HomeBanner(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: buttons.map((button) {
                    final icon = button['icon'];
                    Widget iconWidget;
                    if (icon is String) {
                      iconWidget = Image.asset(
                        icon,
                        width: 30,
                        height: 30,
                        fit: BoxFit.contain,
                      );
                    } else {
                      iconWidget = const SizedBox.shrink();
                    }

                    return GestureDetector(
                      onTap: () {
                        final categoryName = buttonToCategory[button['label']];
                        if (categoryName == null) return;

                        final selectedCategory = mockServiceCategories
                            .firstWhere(
                              (cat) => cat.name == categoryName,
                              orElse: () =>
                                  mockServiceCategories[0], // fallback หมวดแรก
                            );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ServiceCategoryPage(category: selectedCategory),
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
                            child: Center(child: iconWidget),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            button['label'] as String,
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

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  children: mockServiceCategories.map((mainCategory) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Category
                        SizedBox(
                          // ทำให้ Header ชิดซ้าย-ขวาเท่าการ์ด
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 18),
                                child: Text(
                                  mainCategory.name,
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
                                      builder: (context) => ServiceCategoryPage(
                                        category: mainCategory,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // การ์ดโชว์ 2 ใบ
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: List.generate(
                              mainCategory.subServices.length >= 2
                                  ? 2
                                  : mainCategory.subServices.length,
                              (index) {
                                final item = mainCategory.subServices[index];
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),

                                    // ช่วยให้ระยะห่างสวยขึ้น
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
