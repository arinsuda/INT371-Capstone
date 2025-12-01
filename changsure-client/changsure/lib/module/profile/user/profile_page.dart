import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/profile/profile_card_section.dart';
import 'package:changsure/core/profile/services_section.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/services/auth_service.dart';
import 'package:changsure/state/profile_state.dart';
import 'package:changsure/state/bottom_bar_state.dart';
import 'package:changsure/state/auth_state.dart';

import '../../auth/login.dart';
import 'edit_profile.dart';
import 'address_page.dart';
import 'history_service_page.dart';

// Menu item model
class MenuItem {
  final String label;
  final IconData icon;
  final Widget destination;

  const MenuItem({
    required this.label,
    required this.icon,
    required this.destination,
  });
}

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  // Menu items as constants
  static const List<MenuItem> _menuItems = [
    MenuItem(
      label: 'ที่อยู่ของฉัน',
      icon: Icons.pin_drop_outlined,
      destination: CustomerAddressPage(),
    ),
    MenuItem(
      label: 'ประวัติการรับบริการ',
      icon: Icons.history,
      destination: HistoryServicePage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ProfileState>(
          builder: (context, profileState, _) {
            return _buildBody(profileState);
          },
        ),
      ),
    );
  }

  Widget _buildBody(ProfileState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return _buildErrorState(state.error!);
    }

    final profile = state.customerProfile;
    if (profile == null) {
      return const Center(child: Text("ไม่พบข้อมูลผู้ใช้"));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildProfileSection(profile),
        _buildMenuSection(),
        const RecommendedServiceSection(),
        const SizedBox(height: 12),
        _buildLogoutButton(),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "โหลดข้อมูลล้มเหลว",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Center(
      child: Text(
        "โปรไฟล์",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildProfileSection(dynamic profile) {
    return ProfileSection(
      profile: profile,
      profileImageUrl: profile.avatarUrl,
      phone: profile.phone,
      onEdit: _navigateToEditProfile,
    );
  }

  Widget _buildMenuSection() {
    return Padding(
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
          _buildMenuItems(),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: List.generate(_menuItems.length, (index) {
        final item = _menuItems[index];
        final isLast = index == _menuItems.length - 1;

        return Column(
          children: [
            _buildMenuItem(item),
            if (!isLast)
              const Divider(color: Color(0xFFF2F2F2), thickness: 1, height: 1),
          ],
        );
      }),
    );
  }

  Widget _buildMenuItem(MenuItem item) {
    return InkWell(
      onTap: () => _navigateToPage(item.destination),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(item.icon, color: const Color(0xFF737373), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PrimaryButton(text: "ออกจากระบบ", onPressed: _handleLogout),
    );
  }

  // Navigation methods
  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfile()),
    );
  }

  void _navigateToPage(Widget page) {
    context.read<BottomBarState>().setSubPage(page);
  }

  // Logout handler
  Future<void> _handleLogout() async {
    final auth = context.read<AuthState>();
    final bottomBar = context.read<BottomBarState>();
    final profileState = context.read<ProfileState>();

    try {
      await auth.logout();
      profileState.clear();
      bottomBar.setIndex(0);

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(authRepo: context.read<AuthService>()),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
