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

// 👇 เอา model customer profile มาใช้เป็น header adapter
import '../../../models/customers/customer_profile.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class TechnicianProfile extends StatefulWidget {
  const TechnicianProfile({super.key});

  @override
  State<TechnicianProfile> createState() => _ProfileState();
}

class _ProfileState extends State<TechnicianProfile> {
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

            if (state.technicianProfile == null) {
              return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
            }

            final techProfile = state.technicianProfile!;
            final t = techProfile.technician;

            final headerProfile = CustomerProfile(
              id: t.id,
              firstname: t.firstname,
              lastname: t.lastname,
              email: t.email,
              phone: t.phone,
              avatarUrl: t.avatarUrl,
              createdAt: t.createdAt,
              updatedAt: t.updatedAt,
            );

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
                  profile: headerProfile,
                  profileImageUrl: null,
                  phone: null,
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
