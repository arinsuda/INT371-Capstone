import 'package:changsure/data/models/users/users_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/theme.dart';
import 'package:changsure/module/home/home_page.dart';
import 'package:changsure/state/bottom_nav_provider.dart';
import 'package:changsure/state/user_provider.dart';

import 'package:changsure/module/profile/technician/profile_page.dart'
    as tech_profile;
import 'package:changsure/module/profile/technician/viewProfile/view_profile_content.dart'
    as tech_view_profile;
import 'package:changsure/module/profile/technician/edit_profile.dart'
    as tech_edit;
import 'package:changsure/module/profile/technician/address_page.dart'
    as tech_address;
import 'package:changsure/module/profile/technician/view_activities.dart'
    as tech_view_list;
import 'package:changsure/module/profile/technician/activities/post/post_activity_page.dart'
    as tech_post;
import 'package:changsure/module/profile/technician/activities/edit/edit_activity_page.dart'
    as tech_edit_act;
import 'package:changsure/module/profile/technician/activities/view_activity_by_id.dart'
    as tech_view_act;

import 'package:changsure/module/profile/customer/profile_page.dart'
    as user_profile;
import 'package:changsure/module/profile/customer/edit_profile.dart' as user_edit;
import 'package:changsure/module/profile/customer/address_page.dart'
    as user_address;
import 'package:changsure/module/profile/customer/history_service_page.dart'
    as user_history;

class FooterBarTemplate extends ConsumerStatefulWidget {
  const FooterBarTemplate({super.key});

  @override
  ConsumerState<FooterBarTemplate> createState() => _FooterBarTemplateState();
}

class _FooterBarTemplateState extends ConsumerState<FooterBarTemplate>
    with TickerProviderStateMixin {
  int _focusedIndex = -1;

  Widget _assetIcon(
    String inactivePath,
    String activePath,
    int tabIndex,
    int selectedIndex,
  ) {
    final bool isActive = selectedIndex == tabIndex;
    final bool isFocused = _focusedIndex == tabIndex;

    String path;
    if (isFocused) {
      path = activePath;
    } else if (isActive) {
      path = activePath;
    } else {
      path = inactivePath;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: isActive
          ? const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            )
          : null,
      child: Image.asset(
        path,
        width: 24,
        height: 24,
        color: isActive ? Colors.white : const Color(0xFF666666),
      ),
    );
  }

  TextStyle _tabTextStyle(int index, int selectedIndex) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: selectedIndex == index
          ? AppColors.primary
          : const Color(0xFF666666),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final subConfig = ref.watch(bottomSubPageProvider);
    final user = ref.watch(userProvider);
    final userRole = user?.role;
    
    Widget? subPage;
    if (subConfig != null) {
      switch (subConfig.page) {
        // Technician
        case BottomSubPage.technicianViewProfile:
          subPage = const tech_view_profile.ViewProfileContent();
          break;
        case BottomSubPage.technicianEditProfile:
          subPage = const tech_edit.EditProfile();
          break;
        case BottomSubPage.technicianAddressPage:
          subPage = const tech_address.AddressPage();
          break;
        case BottomSubPage.technicianViewActivity:
          subPage = const tech_view_list.ViewActivities();
          break;
        case BottomSubPage.technicianPostActivity:
          subPage = const tech_post.PostActivityPage();
          break;
        case BottomSubPage.technicianViewActivityById:
          if (subConfig.activityId != null) {
            subPage = tech_view_act.ViewActivityById(id: subConfig.activityId!);
          }
          break;
        case BottomSubPage.technicianEditActivity:
          if (subConfig.activityId != null) {
            subPage = tech_edit_act.EditActivityPage(id: subConfig.activityId!);
          }
          break;

        // Customer
        case BottomSubPage.customerEditProfile:
          subPage = const user_edit.EditProfile();
          break;
        case BottomSubPage.customerAddressPage:
          subPage = const user_address.AddressPage();
          break;
        case BottomSubPage.customerHistoryServicePage:
          subPage = const user_history.HistoryServicePage();
          break;

        case BottomSubPage.none:
        default:
          subPage = null;
      }
    }

    List<Widget> getPages() {
      final commonPages = [
        HomePage(),
        const Center(child: Text('ติดตามสถานะ')),
        const Center(child: Text('แชท')),
      ];

      Widget profilePage;
      if (userRole == UserRole.technician) {
        profilePage = const tech_profile.TechnicianProfile();
      } else {
        profilePage = const user_profile.UserProfile();
      }

      return [...commonPages, profilePage];
    }

    final pages = getPages();

    return Scaffold(
      // The main content of the screen
      body: Stack(
        children: [
          // Display the page corresponding to the selected index
          IndexedStack(index: selectedIndex, children: pages),

          // ถ้ามี subpage → วาง overlay ชั้นบนสุด
          if (subPage != null) subPage,
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) {
            final labels = ["หน้าหลัก", "ติดตามสถานะ", "แชท", "โปรไฟล์"];
            final inactivePaths = [
              'assets/icons/home.png',
              'assets/icons/status.png',
              'assets/icons/chat.png',
              'assets/icons/profile.png',
            ];
            final activePaths = [
              'assets/icons/home_active.png',
              'assets/icons/status_active.png',
              'assets/icons/chat_active.png',
              'assets/icons/profile_active.png',
            ];

            return GestureDetector(
              onTapDown: (_) {
                // Set focus state for visual feedback on press
                setState(() {
                  _focusedIndex = index;
                });
              },
              onTapUp: (_) {
                setState(() => _focusedIndex = -1);

                // Update the selected index using Riverpod
                ref.read(bottomNavIndexProvider.notifier).state = index;

                // ปิด sub page ทุกครั้งที่เปลี่ยน tab
                ref.read(bottomSubPageProvider.notifier).state = null;

                // NOTE: Removed the line below as _tabController is not defined
                // _tabController.index = index;
              },
              onTapCancel: () {
                setState(() {
                  _focusedIndex = -1;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _assetIcon(
                    inactivePaths[index],
                    activePaths[index],
                    index,
                    // Use Riverpod's selected index
                    selectedIndex,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    style: _tabTextStyle(
                      index,
                      // Use Riverpod's selected index
                      selectedIndex,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
