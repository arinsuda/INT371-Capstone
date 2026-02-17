import 'package:changsure/module/tracking/payment_page.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'completed_page.dart';
import 'in_progress_page.dart';

class TrackingStatusTab extends StatelessWidget {
  const TrackingStatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(top: 24),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 24),
                    child: Center(
                      child: Text(
                        "ติดตามสถานะ",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.colorTertiaryText,
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: "กำลังดำเนินการ"),
                      Tab(text: "รอชำระเงิน"),
                      Tab(text: "ดำเนินการเสร็จสิ้น"),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: Container(
                color: AppColors.primaryBGHover, // สีพื้นหลังจริง
                child: TabBarView(
                  children: [
                    InProgressPage(),
                    PaymentPage(),
                    CompletedPage(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}
