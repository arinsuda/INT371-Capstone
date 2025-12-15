import 'package:flutter_riverpod/flutter_riverpod.dart';

/// bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// sub pages ที่มีอยู่ในระบบ
enum BottomSubPage {
  none,
  technicianProfile,
  technicianViewProfile,
  technicianEditProfile,
  technicianAddressPage,

  technicianViewActivity,
  technicianEditActivity,
  technicianPostActivity,
  technicianViewActivityById,

  customerProfile,
  customerEditProfile,
  customerAddressPage,
  customerHistoryServicePage,
}

/// config สำหรับหน้า subpage
class SubPageConfig {
  final BottomSubPage page;
  final int? activityId;

  const SubPageConfig({required this.page, this.activityId});
}

/// provider สำหรับ subpage
final bottomSubPageProvider = StateProvider<SubPageConfig?>((ref) => null);
