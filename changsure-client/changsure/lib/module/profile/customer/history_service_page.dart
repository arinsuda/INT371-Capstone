import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import '../../../mockDB/history_service.dart';
import '../../../state/bottom_nav_provider.dart';
import 'historyService/history_service_card.dart';

class HistoryServicePage extends StatelessWidget {
  const HistoryServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          children: [
            // ---------- Header ----------
            Header(header: "ประวัติการรับบริการ"),
            const SizedBox(height: 16),

            Column(
              children: mockHistoryServices.map((service) {
                return ServiceCard(service: service,);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
