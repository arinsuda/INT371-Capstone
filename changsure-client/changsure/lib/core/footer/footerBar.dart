import 'package:changsure/module/home/homePage.dart';
import 'package:flutter/material.dart';
import 'package:motion_tab_bar_v2/motion-tab-bar.dart';
import 'package:motion_tab_bar_v2/motion-tab-controller.dart';
import 'package:provider/provider.dart';
import '../../module/profile/editProfile.dart';
import '../../module/profile/profilePage.dart';
import '../../state/bottomBarState.dart';
import '../theme.dart';

class FooterBarTemplate extends StatefulWidget {
  const FooterBarTemplate({super.key});

  @override
  State<FooterBarTemplate> createState() => _FooterBarTemplateState();
}

class _FooterBarTemplateState extends State<FooterBarTemplate>
    with TickerProviderStateMixin {
  late final MotionTabBarController _motionController;
  int _focusedIndex = -1; // เก็บว่าปุ่มไหนกำลัง focus

  final List<Widget> _pages = [
    HomePage(),
    const Center(child: Text('ติดตามสถานะ')),
    const Center(child: Text('แชท')),
    Profile(),
  ];

  @override
  void initState() {
    super.initState();
    _motionController = MotionTabBarController(
      initialIndex: 0,
      length: _pages.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสร้าง icon ของแต่ละ tab
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
      path = activePath; // focus ใช้ icon แบบ active
    } else if (isActive) {
      path = activePath;
    } else {
      path = inactivePath;
    }

    // Tabs อื่น active → วงกลมฟ้า + icon ขาว
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
    return Consumer<BottomBarState>(
      builder: (context, bottomBarState, child) {
        final selectedIndex = bottomBarState.selectedIndex;

        return Scaffold(
          body: Stack(
            children: [
              IndexedStack(index: selectedIndex, children: _pages),
              if (bottomBarState.currentSubPage != null)
                bottomBarState.currentSubPage!,
            ],
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 45),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26, // สีเงา
                    blurRadius: 8, // ความเบลอของเงา
                    offset: const Offset(0, -2), // เงาด้านบน (-y) หรือด้านล่าง (+y)
                  ),
                ]
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
                      setState(() {
                        _focusedIndex = index;
                      });
                    },
                    onTapUp: (_) {
                      setState(() {
                        _focusedIndex = -1;
                      });
                      bottomBarState.setIndex(index);
                      _motionController.index = index;
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
          ),
        );
      },
    );
  }
}
