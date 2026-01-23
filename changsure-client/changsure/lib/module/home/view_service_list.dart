import 'package:changsure/core/header.dart';
import 'package:changsure/module/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/master_data_models.dart';
import '../../mockDB/service_categories.dart';
import '../../state/bottom_nav_provider.dart';
import './homePage/service_card.dart';

class ServiceCategoryPage extends StatelessWidget {
  final ServiceCategoryModel category;
  final int? provinceId;

  const ServiceCategoryPage({
    super.key,
    required this.category,
    required this.provinceId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              header: category.catName,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 คอลัมน์
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.72, // ปรับความสูงการ์ด
                  ),
                  itemCount: category.services.length,
                  itemBuilder: (context, index) {
                    return ServiceCard(
                      data: category.services[index],
                      provinceId: provinceId,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
