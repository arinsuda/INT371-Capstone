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
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      context.read<ServiceCategoryState>().loadCategories();
      context.read<ServiceState>().loadServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildContent(context);
    } catch (e, stack) {
      debugPrint("=== HOME UI ERROR ===");
      debugPrint("Error: $e");
      debugPrint("Stack:\n$stack");

      return Scaffold(
        body: Center(
          child: SelectableText(
            "UI Error:\n$e\n\nStack:\n$stack",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context) {
    // final categoryState = context.watch<ServiceCategoryState>();
    // final serviceState = context.watch<ServiceState>();
    final categoryState = context.read<ServiceCategoryState>();
    final serviceState = context.read<ServiceState>();


    if (categoryState.loading || serviceState.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (categoryState.errorMessage != null || serviceState.error != null) {
      return Scaffold(
        body: Center(
          child: SelectableText(
            "เกิดข้อผิดพลาดจาก API:\n${serviceState.error}\n\nStack:\n${serviceState.errorStack}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final categories = categoryState.categories ?? [];
    final services = serviceState.services ?? [];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const HomeBanner(),
          _buildCategoryShortcuts(categories),
          const SizedBox(height: 20),
          ..._buildCategoryServiceSections(categories, services),
        ],
      ),
    );
  }

  // -----------------------------------------------------
  //  ปุ่มลัด 4 หมวดหมู่แรก
  // -----------------------------------------------------
  Widget _buildCategoryShortcuts(List categories) {
    final shortcuts = categories.take(4).toList();

    final buttons = [
      {'label': 'ทาสี', 'icon': 'assets/icons/painted.png'},
      {'label': 'การประปา', 'icon': 'assets/icons/waterWork.png'},
      // Asset
      {'label': 'การไฟฟ้า', 'icon': 'assets/icons/powerSupply.png'},
      // Asset
      {'label': 'เครื่องใช้ไฟฟ้า', 'icon': 'assets/icons/electric.png'},
      // Asset
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: shortcuts.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;

          final fallbackIcon = buttons[index]['icon'];

          return GestureDetector(
            onTap: () => _navigateToCategory(cat.id, cat.catName),
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
                    child: (cat.iconUrl != null && cat.iconUrl!.isNotEmpty)
                        ? Image.network(
                            cat.iconUrl!,
                            width: 30,
                            height: 30,
                            errorBuilder: (_, __, ___) => Image.asset(
                              fallbackIcon!,
                              width: 30,
                              height: 30,
                            ),
                          )
                        : Image.asset(fallbackIcon!, width: 30, height: 30),
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
    );
  }

  // -----------------------------------------------------
  //  Section แยกตามหมวดหมู่
  // -----------------------------------------------------
  List<Widget> _buildCategoryServiceSections(List categories, List services) {
    return categories.map((cat) {
      final items = services
          .where((s) => s.categoryId != null && s.categoryId == cat.id)
          .toList();

      if (items.isEmpty) return const SizedBox();

      final showItems = items.take(2).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryHeader(cat),
          _buildServiceRow(showItems),
          const SizedBox(height: 20),
        ],
      );
    }).toList();
  }

  // Header หมวดหมู่
  Widget _buildCategoryHeader(cat) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
            icon: const Icon(Icons.chevron_right, color: AppColors.primary),
            onPressed: () => _navigateToCategory(cat.id, cat.catName),
          ),
        ],
      ),
    );
  }

  // การ์ด 2 อัน
  Widget _buildServiceRow(List showItems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: List.generate(showItems.length, (i) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SizedBox(
                height: 220,
                child: ServiceCard(data: showItems[i]),
              ),
            ),
          );
        }),
      ),
    );
  }

  // -----------------------------------------------------
  // Navigation
  // -----------------------------------------------------
  void _navigateToCategory(int categoryId, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceCategoryPage(
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      ),
    );
  }
}
