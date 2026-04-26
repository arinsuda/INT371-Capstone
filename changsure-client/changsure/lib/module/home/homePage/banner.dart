import 'dart:async';

import 'package:changsure/data/models/notification_model.dart';
import 'package:changsure/module/home/homePage/widgets/in_app_notification_banner.dart';
import 'package:changsure/module/home/homePage/widgets/notification_badge_button.dart';
import 'package:changsure/state/notifications/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../state/master_data_provider.dart';

class HomeBanner extends ConsumerStatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int> onProvinceChanged;

  const HomeBanner({
    super.key,
    required this.onSearchChanged,
    required this.onProvinceChanged,
  });

  @override
  ConsumerState<HomeBanner> createState() => _HomeBannerState();
}

class _HomeBannerState extends ConsumerState<HomeBanner> {
  String selectedProvince = "กรุงเทพมหานคร";
  NotificationModel? _currentNotification;
  Timer? _notificationTimer;
  bool _showBanner = false;

  void _showNotificationBanner(NotificationModel notification) {
    _notificationTimer?.cancel();

    setState(() {
      _currentNotification = notification;
      _showBanner = true;
    });

    _notificationTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showBanner = false;
        });
      }
    });
  }

  late PageController _pageController;
  int _currentBannerIndex = 0;

  final List<String> _banners = [
    "assets/image/changsure_banner.png",
    "assets/image/banner.png",
  ];

  Timer? _bannerTimer;

  void _startBannerAutoSlide() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_pageController.hasClients) return;

      int nextPage = _currentBannerIndex + 1;

      if (nextPage >= _banners.length) {
        nextPage = 0;
      }

      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _closeBanner() {
    _notificationTimer?.cancel();
    setState(() {
      _showBanner = false;
    });
  }

  void _openProvinceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final provincesAsync = ref.watch(provincesProvider);

        return provincesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Error: $e'),
          ),
          data: (provinces) {
            return ListView(
              shrinkWrap: true,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "เลือกจังหวัดที่ต้องการรับบริการ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                ...provinces.map(
                  (p) => ListTile(
                    title: Text(p.nameTh),
                    onTap: () {
                      setState(() {
                        selectedProvince = p.nameTh;
                      });

                      widget.onProvinceChanged(p.id);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _startBannerAutoSlide();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    _bannerTimer?.cancel();
    _pageController.dispose(); // 👈 สำคัญ
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotificationState>(notificationProvider, (previous, next) {
      if (previous != null && next.items.length > previous.items.length) {
        final unreadNotifications = next.items.where((n) => !n.isRead).toList();

        if (unreadNotifications.isNotEmpty) {
          _showNotificationBanner(unreadNotifications.first);
        }
      }
    });

    return SizedBox(
      height: 320, // ความสูงรวม Banner + Search bar
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner + gradient
          SizedBox(
            height: 270,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _banners.length,
              onPageChanged: (index) {
                setState(() {
                  _currentBannerIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_banners[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 270,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFB7CFFF).withOpacity(0.1),
                  AppColors.primary.withOpacity(0.1),
                  const Color(0xFF001F9F).withOpacity(0.2),
                  const Color(0xFF020927).withOpacity(0.5),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (index) {
                bool isActive = index == _currentBannerIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 10 : 6,
                  height: isActive ? 10 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.white54,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),

          // ปุ่มจังหวัด + notifications
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _openProvinceSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 5),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Color(0xFF3071C7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          selectedProvince,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3071C7),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF3071C7),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: NotificationBadgeButton(),
                ),
              ],
            ),
          ),

          Positioned(
            top: 240,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.colorStroke),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: TextField(
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: "ค้นหาบริการ...",
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFAAAAAA),
                  ),

                  suffixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 14,
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            top: _showBanner ? 40 : -150,
            left: 0,
            right: 0,
            child: _currentNotification != null
                ? InAppNotificationBanner(
                    notification: _currentNotification!,
                    onDismiss: _closeBanner,
                    onTap: () {
                      _closeBanner();
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
