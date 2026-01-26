import 'package:flutter/material.dart';

import '../../core/header.dart';
import '../../core/theme.dart';

class TrackingStatusTab extends StatelessWidget {
  const TrackingStatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: 16, top: 24),
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

              // TabBar
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF9B9B9B),
                indicatorColor: AppColors.primary,

                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),

                tabs: const [
                  Tab(text: "กำลังดำเนินการ"),
                  Tab(text: "รอชำระเงิน"),
                  Tab(text: "ดำเนินการเสร็จสิ้น"),
                ],
              ),


              // TabBarView
              Expanded(child: TabBarView(children: const [])),
            ],
          ),
        ),
      ),
    );
  }
}
