import 'package:flutter_riverpod/flutter_riverpod.dart';

/// bottom navigation index
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

/// sub pages ที่มีอยู่ในระบบ
enum BottomSubPage {
  none,
  addressPage,

  technicianProfile,
  technicianViewProfile,
  technicianEditProfile,

  technicianViewActivity,
  technicianEditActivity,
  technicianPostActivity,
  technicianViewActivityById,

  customerProfile,
  customerEditProfile,
  customerHistoryServicePage,

  publicTechnicianProfile, 
  publicActivityDetail,
}

/// config สำหรับหน้า subpage
class SubPageConfig {
  final BottomSubPage page;
  final int? activityId;
  final int? technicianId;

  const SubPageConfig({required this.page, this.activityId, this.technicianId});
}

/// provider สำหรับ subpage
final bottomSubPageProvider = StateProvider<SubPageConfig?>((ref) => null);
