import 'package:changsure/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/core/profile/profile_card_section.dart';
import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/profile/services_section.dart';
import 'package:changsure/state/bottom_nav_provider.dart';
import '../widgets/action_button_section.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class TechnicianProfile extends ConsumerStatefulWidget {
  const TechnicianProfile({super.key});

  @override
  ConsumerState<TechnicianProfile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<TechnicianProfile> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    final tech = user?.technicianProfile;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          controller: _scrollController,
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
              profileImage:
                  (tech?.avatarUrl != null && tech!.avatarUrl!.isNotEmpty)
                  ? tech.avatarUrl!
                  : 'assets/image/Technician.png',
              fullName: tech?.fullName ?? 'ไม่ระบุชื่อ',
              email: tech?.email ?? '-',
              phone: tech?.phone ?? '-',
              onEdit: () {
                ref
                    .read(bottomSubPageProvider.notifier)
                    .state = const SubPageConfig(
                  page: BottomSubPage.technicianEditProfile,
                );
              },
            ),
            ActionButtonSection(),
            RecommendedServiceSection(),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PrimaryButton(
                text: "ออกจากระบบ",
                onPressed: () {
                  ref.read(userProvider.notifier).logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
