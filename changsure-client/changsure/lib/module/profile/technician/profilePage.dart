import 'package:changsure/core/button/primaryButton.dart';
import 'package:changsure/core/profile/servicesSection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../state/bottomBarState.dart';
import '../../../state/profile_state.dart';
import 'package:changsure/core/profile/profileCardSection.dart';
import 'actionButtonSection.dart';
import 'package:changsure/module/profile/technician/editProfile.dart';
import 'viewProfileTab.dart';

import '../../../state/auth_state.dart';
import '../../../repositories/auth_repository.dart';
import 'package:changsure/module/auth/login.dart';

class TechnicianProfile extends StatefulWidget {
  const TechnicianProfile({super.key});

  @override
  State<TechnicianProfile> createState() => _TechnicianProfileState();
}

class _TechnicianProfileState extends State<TechnicianProfile> {
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
              return Center(child: Text("โหลดข้อมูลล้มเหลว: ${state.error}"));
            }

            final profile = state.technicianProfile;
            if (profile == null) {
              return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
            }

            final tech = profile.technician;

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
              children: [
                Center(
                  child: Text(
                    "โปรไฟล์",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ProfileSection(
                  profile: profile,
                  profileImageUrl: tech.avatarUrl,
                  phone: tech.phone,
                  onEdit: () {
                    context.read<BottomBarState>().setSubPage(
                      const EditProfile(),
                    );
                  },
                ),

                const ActionButtonSection(),
                const ViewProfilePage(),
                const RecommendedServiceSection(),

                const SizedBox(height: 12),
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
                          builder: (_) {
                            final authRepo = context.read<AuthRepository>();
                            return LoginScreen(authRepo: authRepo);
                          },
                        ),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
