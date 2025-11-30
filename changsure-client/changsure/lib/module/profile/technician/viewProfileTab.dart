import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './viewProfile/viewProfileContent.dart';
import './viewProfile/reviewContent.dart';
import '../../../state/profile_state.dart';
import '../../../core/theme.dart';

class ViewProfilePage extends StatefulWidget {
  const ViewProfilePage({super.key});

  @override
  State<ViewProfilePage> createState() => _ViewProfilePageState();
}

class _ViewProfilePageState extends State<ViewProfilePage> {
  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลถ้ายังไม่มี
    Future.microtask(() {
      final profileState = context.read<ProfileState>();
      if (profileState.technicianProfile == null) {
        profileState.loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<ProfileState>(
            builder: (context, state, child) {
              // แสดง Loading
              if (state.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              // แสดง Error
              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("โหลดข้อมูลล้มเหลว: ${state.error}"),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => state.loadProfile(),
                        child: const Text("ลองใหม่"),
                      ),
                    ],
                  ),
                );
              }

              // แสดงหน้าจริง
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Header(header: "ดูโปรไฟล์"),
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
                      children: const [ViewProfileContent(), ReviewContent()],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
