import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '';
import '../../../mockDB/historyService.dart';
import '../../../state/bottomBarState.dart';
import 'historyService/historyServiceCard.dart';

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
            Header(header: "ประวัติการเับบริการ"),
            const SizedBox(height: 16),

            Column(
              children: mockHistoryServices.map((service) {
                return ServiceCard(service: service);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
