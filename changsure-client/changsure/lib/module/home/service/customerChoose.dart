import 'package:changsure/module/home/service/serviceDetails/ctm_TechnicianCard.dart';
import 'package:flutter/material.dart';

import '../../../core/header.dart';
import '../../../core/theme.dart';
import '../../../mockDB/technician.dart';

class CustomerChoose extends StatelessWidget {
  final String serviceName;
  final String category;

  const CustomerChoose({
    super.key,
    required this.serviceName,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final List<Technician> filteredTechnicians = mockTechnicians
        .where((tech) => tech.category == category)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            Header(
              header: "เลือกช่างด้วยตนเอง",
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),

            //Title
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),
                  const Text(
                    "คุณต้องการเลือกช่างคนไหน",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.colorTertiaryText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: filteredTechnicians
                    .map(
                      (tech) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TechnicianCardCTM(technician: tech),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
