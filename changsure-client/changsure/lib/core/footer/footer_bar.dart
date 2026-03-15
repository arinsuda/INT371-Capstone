import 'package:changsure/data/models/users/users_model.dart';
import 'package:changsure/module/tracking/tracking_status_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:changsure/core/theme.dart';
import 'package:changsure/module/home/home_page.dart';
import 'package:changsure/module/chat/chat_list_page.dart';
import 'package:changsure/state/bottom_nav_provider.dart';
import 'package:changsure/state/user_provider.dart';

import 'package:changsure/module/profile/address_page.dart' as shared_address;

import 'package:changsure/module/profile/technician/pages/profile_page.dart'
    as tech_me_profile;
import 'package:changsure/module/profile/technician/pages/technician_view_page.dart'
    as tech_profile;
import 'package:changsure/module/profile/technician/pages/edit_profile_page.dart'
    as tech_edit;
import 'package:changsure/module/profile/technician/activities/pages/activities_list_page.dart'
    as tech_view_list;
import 'package:changsure/module/profile/technician/activities/pages/post_activity_page.dart'
    as tech_post;
import 'package:changsure/module/profile/technician/activities/pages/edit_activity_page.dart'
    as tech_edit_act;
import 'package:changsure/module/profile/technician/activities/pages/activity_detail_page.dart'
    as tech_view_act;

import 'package:changsure/module/profile/customer/profile_page.dart'
    as user_profile;
import 'package:changsure/module/profile/customer/edit_profile.dart'
    as user_edit;
import 'package:changsure/module/profile/customer/history_service_page.dart'
    as user_history;
import 'package:flutter_svg/svg.dart';

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

  Widget _svgIcon(String iconPath, int tabIndex, int selectedIndex) {
    final bool isActive = selectedIndex == tabIndex;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [

        /// วงกลมขาว (เลื่อนขึ้น)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          bottom: isActive ? 8 : 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 60 : 0,
            height: isActive ? 60 : 0,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),

        /// icon + primary circle (ลอยขึ้น)
        AnimatedSlide(
          offset: isActive ? const Offset(0, -0.25) : Offset.zero,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(isActive ? 14 : 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: AnimatedScale(
              scale: isActive ? 1.2 : 1.0,
              duration: const Duration(milliseconds: 250),
              child: SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isActive ? Colors.white : const Color(0xFF666666),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabLabel(String label, bool isActive, BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;

    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      style: baseStyle!.copyWith(
        fontSize: isActive ? 12 : 12,
        fontWeight: FontWeight.w600,
        color: isActive ? AppColors.primary : const Color(0xFF666666),
      ),
      child: Text(label),
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
        case BottomSubPage.addressPage:
          subPage = const shared_address.AddressPage();
          break;
        case BottomSubPage.technicianViewProfile:
          subPage = const tech_profile.TechnicianProfilePage(isOwner: true);
          break;
        case BottomSubPage.technicianEditProfile:
          subPage = const tech_edit.EditProfile();
          break;
        case BottomSubPage.technicianViewActivity:
          subPage = const tech_view_list.ViewActivities();
          break;
        case BottomSubPage.technicianPostActivity:
          subPage = const tech_post.PostActivityPage();
          break;
        case BottomSubPage.technicianViewActivityById:
          if (subConfig.activityId != null) {
            subPage = tech_view_act.ActivityDetailPage(
              postId: subConfig.activityId!,
            );
          }
          break;
        case BottomSubPage.technicianEditActivity:
          if (subConfig.activityId != null) {
            subPage = tech_edit_act.EditActivityPage(id: subConfig.activityId!);
          }
          break;

        case BottomSubPage.customerEditProfile:
          subPage = const user_edit.EditProfile();
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
        const HomePage(),
        const TrackingStatusTab(),
        const ChatListPage(),
      ];

      Widget profilePage;
      if (userRole == UserRole.technician) {
        profilePage = const tech_me_profile.TechnicianProfile();
      } else {
        profilePage = const user_profile.UserProfile();
      }

      return [...commonPages, profilePage];
    }

    final pages = getPages();

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: selectedIndex, children: pages),

          if (subPage != null) subPage,
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(4, (index) {
            final labels = ["หน้าหลัก", "ติดตามสถานะ", "แชท", "โปรไฟล์"];
            final icons = [
              'assets/icons/homeIcon.svg',
              'assets/icons/statusIcon.svg',
              'assets/icons/chatIcon.svg',
              'assets/icons/userIcon.svg',
            ];

            return Expanded(
                child:
              InkWell(
              onTapDown: (_) {
                setState(() {
                  _focusedIndex = index;
                });
              },
              onTapUp: (_) {
                setState(() => _focusedIndex = -1);

                ref.read(bottomNavIndexProvider.notifier).state = index;

                ref.read(bottomSubPageProvider.notifier).state = null;
              },
              onTapCancel: () {
                setState(() {
                  _focusedIndex = -1;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 50, // ล็อกพื้นที่ icon
                    child: _svgIcon(icons[index], index, selectedIndex),
                  ),
                  _tabLabel(
                    labels[index],
                    selectedIndex == index,
                    context,
                  ),
                ],
              ),
            ));
          }),
        ),
      ),
    );
  }
}
