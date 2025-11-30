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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileState>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileState>(
      builder: (context, state, child) {
        // โหลดข้อมูลอยู่ → ให้แสดงแค่ loading ป้องกัน TabBarView ถูกสร้าง
        if (state.loading && state.technicianProfile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // error และไม่มีข้อมูลเลย
        if (state.error != null && state.technicianProfile == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => state.loadProfile(),
                    child: const Text("ลองใหม่"),
                  ),
                ],
              ),
            ),
          );
        }

        // ยังไม่ควรสร้าง UI จนกว่าจะมีข้อมูลจริง
        if (state.technicianProfile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ✨ มีข้อมูลแล้ว → สร้างหน้าโปรไฟล์ได้
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Header(header: "ดูโปรไฟล์"),
                  ),
                  TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: const Color(0xFF9B9B9B),
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: "โปรไฟล์ช่าง"),
                      Tab(text: "รีวิวช่าง"),
                    ],
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        const TabBarView(
                          children: [ViewProfileContent(), ReviewContent()],
                        ),

                        if (state.loading)
                          Container(
                            color: Colors.black12,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
