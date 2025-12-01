import 'package:flutter/material.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';
import 'package:provider/provider.dart';

// Page imports
import '../../module/home/home_page.dart';
import '../../module/profile/technician/profile_page.dart';
import '../../module/profile/user/profile_page.dart';

// States
import '../../state/bottom_bar_state.dart';
import '../../state/auth_state.dart';
import '../../state/profile_state.dart';

// Theme
import '../theme.dart';

class FooterBarTemplate extends StatefulWidget {
  const FooterBarTemplate({super.key});

  @override
  State<FooterBarTemplate> createState() => _FooterBarTemplateState();
}

class _FooterBarTemplateState extends State<FooterBarTemplate>
    with TickerProviderStateMixin {
  late final MotionTabBarController _motionController;
  int _focusedIndex = -1;

  @override
  void initState() {
    super.initState();
    _motionController = MotionTabBarController(
      initialIndex: 0,
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  List<Widget> _getPages(AuthState authState) {
    final bool isTechnician = authState.role == 'technician';
    return [
      const HomePage(),
      const Center(child: Text('ติดตามสถานะ')),
      const Center(child: Text('แชท')),
      isTechnician ? const TechnicianProfile() : const UserProfile(),
    ];
  }

  Widget _assetIcon(
    String inactivePath,
    String activePath,
    int tabIndex,
    int selectedIndex,
  ) {
    final bool isActive = selectedIndex == tabIndex;
    final bool isFocused = _focusedIndex == tabIndex;

    final String path = (isFocused || isActive) ? activePath : inactivePath;

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
    return Consumer2<BottomBarState, AuthState>(
      builder: (context, bottomBarState, authState, child) {
        final int selectedIndex = bottomBarState.selectedIndex;
        final pages = _getPages(authState);

        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(index: selectedIndex, children: pages),

              // ถ้ามี subpage ให้แสดงทับ
              if (bottomBarState.currentSubPage != null)
                bottomBarState.currentSubPage!,
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
                const labels = ["หน้าหลัก", "ติดตามสถานะ", "แชท", "โปรไฟล์"];
                const inactivePaths = [
                  'assets/icons/home.png',
                  'assets/icons/status.png',
                  'assets/icons/chat.png',
                  'assets/icons/profile.png',
                ];
                const activePaths = [
                  'assets/icons/home_active.png',
                  'assets/icons/status_active.png',
                  'assets/icons/chat_active.png',
                  'assets/icons/profile_active.png',
                ];

                return GestureDetector(
                  onTapDown: (_) {
                    setState(() {
                      _focusedIndex = index;
                    });
                  },
                  onTapUp: (_) async {
                    setState(() {
                      _focusedIndex = -1;
                    });

                    bottomBarState.setIndex(index);

                    // โหลดโปรไฟล์เมื่อกด tab โปรไฟล์
                    if (index == 3) {
                      await context.read<ProfileState>().loadProfile();
                    }
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
                        selectedIndex,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[index],
                        style: _tabTextStyle(index, selectedIndex),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}
