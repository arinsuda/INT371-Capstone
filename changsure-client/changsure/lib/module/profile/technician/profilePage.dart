import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/profile/servicesSection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../state/bottomBarState.dart';
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
        child: ListView(
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
              profileImage: 'assets/image/Technician.png',
              fullName: 'สมชาย ใจดี',
              email: 'somchai@example.com',
              phone: '081-234-5678',
              onEdit: () {
                Provider.of<BottomBarState>(context, listen: false).setSubPage(const EditProfile());
              },
            ),
            ActionButtonSection(),
            RecommendedServiceSection(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PrimaryButton(text: "ออกจากระบบ", onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }
}
