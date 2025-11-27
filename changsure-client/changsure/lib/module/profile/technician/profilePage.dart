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

            if (state.profile == null) {
              return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
            }

            final profile = state.profile!;

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
                  profile: profile,
                  profileImageUrl: null,
                  phone: null,
                  onEdit: () {
                    Provider.of<BottomBarState>(
                      context,
                      listen: false,
                    ).setSubPage(const EditProfile());
                  },
                ),

                ActionButtonSection(),

                const ViewProfilePage(),

                // recommended services
                RecommendedServiceSection(),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PrimaryButton(
                    text: "ออกจากระบบ",
                    onPressed: () {
                      // TODO: ผูก logout จริงกับ AuthState ได้
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
