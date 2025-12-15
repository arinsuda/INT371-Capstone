import 'package:changsure/state/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../state/bottom_nav_provider.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/profile/services_section.dart';
import 'package:changsure/core/profile/profile_card_section.dart';

double toLogicalPx(BuildContext context, double px) =>
    px / MediaQuery.of(context).devicePixelRatio;

class UserProfile extends ConsumerStatefulWidget {
  const UserProfile({super.key});

  @override
  ConsumerState<UserProfile> createState() => _ProfileState();
}

class _ProfileState extends ConsumerState<UserProfile> {
  final items = [
    {'label': 'ที่อยู่ของฉัน', 'icon': Icons.pin_drop_outlined},
    // {'label': 'ประวัติการรับบริการ', 'icon': Icons.history},
  ];

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
              fullName: 'สมศักดิ์ หนวดเยิ้ม',
              email: 'somchai@example.com',
              phone: '081-234-5678',
              onEdit: () {
                ref
                    .read(bottomSubPageProvider.notifier)
                    .state = const SubPageConfig(
                  page: BottomSubPage.customerEditProfile,
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
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
                      final isLast = index == items.length - 1;

                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              if (item['label'] == 'ที่อยู่ของฉัน') {
                                ref
                                    .read(bottomSubPageProvider.notifier)
                                    .state = const SubPageConfig(
                                  page: BottomSubPage.customerAddressPage,
                                );
                              } else if (item['label'] ==
                                  'ประวัติการรับบริการ') {
                                ref
                                    .read(bottomSubPageProvider.notifier)
                                    .state = const SubPageConfig(
                                  page:
                                      BottomSubPage.customerHistoryServicePage,
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
