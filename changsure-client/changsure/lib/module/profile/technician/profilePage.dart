import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../state/profile_state.dart';
import '../../../state/auth_state.dart';
import '../../../state/bottomBarState.dart';
import '../../../services/auth_service.dart';

import '../../../core/profile/profileCardSection.dart';
import '../../../core/button/primaryButton.dart';
import '../../../core/profile/servicesSection.dart';

import 'actionButtonSection.dart';
import 'viewProfileTab.dart';
import '../../auth/login.dart';
import '../technician/editProfile.dart';

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
            if (state.loading) {
              return const Center(child: CircularProgressIndicator());
            }

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

            final tech = state.technicianProfile;
            if (tech == null) {
              return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfile()),
                    );
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

                      Navigator.of(context).pushAndRemoveUntil(
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
            );
          },
        ),
      ),
    );
  }
}
