import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';

import '../../mockDB/serviceCategories.dart';
import './homePage/serviceCard.dart';

class ServiceCategoryPage extends StatelessWidget {
  final ServiceCategories category;

  const ServiceCategoryPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(header: category.name),
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
                  itemCount: category.subServices.length,
                  itemBuilder: (context, index) {
                    return ServiceCard(data: category.subServices[index]);
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

