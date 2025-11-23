import 'package:changsure/module/profile/technician/viewProfile/reviewContent.dart';
import 'package:flutter/material.dart';
import './viewProfile/viewProfileContent.dart';
import './viewProfile/reviewContent.dart';
import 'package:provider/provider.dart';
import '../../../state/bottomBarState.dart';
import '../../../core/theme.dart';

class ViewProfilePage extends StatelessWidget {
  const ViewProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Provider.of<BottomBarState>(
                          context,
                          listen: false,
                        ).closeSubPage();
                      },
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "ดูโปรไฟล์ช่าง",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004AAD),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // TabBar
              TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF9B9B9B),
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: "โปรไฟล์ช่าง"),
                  Tab(text: "รีวิวช่าง"),
                ],
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  children: const [
                    ViewProfileContent(),
                    ReviewContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
