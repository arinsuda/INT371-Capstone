import 'package:changsure/core/button/primaryButton.dart';
import 'package:changsure/core/profile/servicesSection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:changsure/core/profile/profileCardSection.dart';
import 'package:changsure/module/profile/user/editProfile.dart';

import '../../../core/theme.dart';
import '../../../state/bottomBarState.dart';
import '../../../state/profile_state.dart';

import '../../../repositories/auth_repository.dart';
import '../../../state/auth_state.dart';
import '../../auth/login.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _ProfileState();
}

class _ProfileState extends State<UserProfile> {
  final items = [
    {'label': 'ที่อยู่ของฉัน', 'icon': Icons.pin_drop_outlined},
    {'label': 'ประวัติการรับบริการ', 'icon': Icons.history},
  ];

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

            if (state.customerProfile == null) {
              return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
            }

            final profile = state.customerProfile!;

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
                  onEdit: () {
                    Provider.of<BottomBarState>(
                      context,
                      listen: false,
                    ).setSubPage(const EditProfile());
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ข้อมูลการใช้งาน',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final isLast = index == items.length;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item['icon'] as IconData,
                                      color: const Color(0xFF737373),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item['label'] as String,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFFAAAAAA),
                                      size: 24,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                const Divider(
                                  color: Color(0xFFF2F2F2),
                                  thickness: 1,
                                  height: 1,
                                ),
                            ],
                          );
                        }),
                      ),
                    ],
                  ),
                ),

                RecommendedServiceSection(),

                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PrimaryButton(
                    text: "ออกจากระบบ",
                    onPressed: () async {
                      final auth = context.read<AuthState>();
                      await auth.logout();

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
