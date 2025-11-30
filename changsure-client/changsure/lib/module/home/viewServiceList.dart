import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:changsure/state/service_state.dart';
import './homePage/serviceCard.dart';

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

    Future.microtask(() {
      context.read<ServiceState>().fetchServices(categoryId: widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceState = context.watch<ServiceState>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Header(
              header: widget.categoryName,
              onPressed: () => Navigator.pop(context),
            ),

            Expanded(
              child: serviceState.loading
                  ? const Center(child: CircularProgressIndicator())
                  : serviceState.error != null
                  ? Center(
                      child: Text(
                        "Error: ${serviceState.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: serviceState.services.length,
                        itemBuilder: (context, index) {
                          final item = serviceState.services[index];
                          return ServiceCard(data: item);
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
