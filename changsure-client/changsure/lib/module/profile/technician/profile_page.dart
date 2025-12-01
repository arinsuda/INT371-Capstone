import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../state/profile_state.dart';
import '../../../state/auth_state.dart';
import 'package:changsure/state/bottom_bar_state.dart';
import '../../../services/auth_service.dart';

import '../../../core/profile/profile_card_section.dart';
import '../../../core/button/primary_button.dart';
import '../../../core/profile/services_section.dart';

import 'action_button_section.dart';
import 'view_profile_tab.dart';
import '../../auth/login.dart';
import '../technician/edit_profile.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class TechnicianProfile extends StatefulWidget {
  const TechnicianProfile({super.key});

  @override
  State<TechnicianProfile> createState() => _ProfileState();
}

class _ProfileState extends State<TechnicianProfile> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ProfileState>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ProfileState>(
          builder: (context, state, child) {
            // Loading
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error
            if (state.error != null) {
              final errorText = state.error!.contains("type")
                  ? "⚠️ รูปแบบข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง\n\nรายละเอียด: ${state.error}"
                  : state.error;

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "โหลดข้อมูลล้มเหลว",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorText ?? "เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ",
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => state.loadProfile(),
                      child: const Text("ลองใหม่"),
                    ),
                  ],
                ),
              );
            }

            // Data not found
            final tech = state.technicianProfile;
            if (tech == null) {
              return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
            }

            // ⭐ ใช้ SingleChildScrollView แทน listview-in-listview
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "โปรไฟล์",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    ProfileSection(
                      profile: tech,
                      profileImageUrl: tech.avatarUrl,
                      phone: tech.phone,
                      onEdit: () {
                        Provider.of<BottomBarState>(context, listen: false).setSubPage(const EditProfile());
                      },
                    ),

                    const SizedBox(height: 20),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ActionButtonSection(),
                    ),

                    const SizedBox(height: 20),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: RecommendedServiceSection(),
                    ),

                    const SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: PrimaryButton(
                        text: "ออกจากระบบ",
                        onPressed: () async {
                          final auth = context.read<AuthState>();
                          final profileState = context.read<ProfileState>();
                          final bottomBar = context.read<BottomBarState>();

                          await auth.logout();
                          profileState.clear();
                          bottomBar.setIndex(0);

                          if (!mounted) return;

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginScreen(
                                authRepo: context.read<AuthService>(),
                              ),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
