import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:changsure/state/service_state.dart';
import './homePage/service_card.dart';

class ServiceCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const ServiceCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<ServiceCategoryPage> createState() => _ServiceCategoryPageState();
}

class _ServiceCategoryPageState extends State<ServiceCategoryPage> {
  @override
  void initState() {
    super.initState();

    /// โหลดเฉพาะ service ของ category นี้
    Future.microtask(() {
      context.read<ServiceState>().fetchServices(categoryId: widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = context.watch<ServiceState>();

    final isLoading = serviceState.loading;
    final error = serviceState.error;
    final items =
        serviceState.services; // ปลอดภัย null → empty ใน State อยู่แล้ว

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              header: widget.categoryName,
              onPressed: () => Navigator.pop(context),
            ),

            Expanded(
              child: Builder(
                builder: (_) {
                  if (isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (error != null) {
                    return Center(
                      child: Text(
                        "เกิดข้อผิดพลาด: $error",
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        "ยังไม่มีบริการในหมวดนี้",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.72,
                          ),
                      itemBuilder: (_, index) {
                        return ServiceCard(data: items[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
