import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/module/profile/servicesSection.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'profileCardSection.dart'; // ProfileSection
import 'actionButtonSection.dart'; // ActionButtonSection

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ProfileSection(
              profileImage: 'assets/image/Technician.png',
              fullName: 'สมชาย ใจดี',
              email: 'somchai@example.com',
              phone: '081-234-5678',
              onEdit: () {},
            ),
            ActionButtonSection(),
            RecommendedServiceSection(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PrimaryButton(
                text: "ออกจากระบบ",
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );

  }
}
