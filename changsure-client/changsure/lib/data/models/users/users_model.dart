import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/data/models/customer/customer_model.dart';

// Enum เพื่อแยกสถานะ
enum UserRole { technician, customer, guest }

class UserModel {
  final UserRole role;
  final String? token;

  final TechnicianModel? technicianProfile;
  final CustomerModel? customerProfile;

  UserModel({
    required this.role,
    this.token,
    this.technicianProfile,
    this.customerProfile,
  });


  // เช็คว่าตอนนี้มี Token ไหม (Login หรือยัง)
  bool get isAuthenticated => token != null;

  // ดึงชื่อ (ไม่ว่าเป็นช่างหรือลูกค้า)
  String get fullName {
    if (role == UserRole.technician) {
      return technicianProfile?.fullName ?? 'Unknown Technician';
    } else if (role == UserRole.customer) {
      return customerProfile?.fullName ?? 'Unknown Customer';
    }
    return 'Guest';
  }

  // ดึงรูปโปรไฟล์
  String? get avatarUrl {
    if (role == UserRole.technician) return technicianProfile?.avatarUrl;
    if (role == UserRole.customer) return customerProfile?.avatarUrl;
    return null;
  }

  // Method copyWith (มีประโยชน์มากตอนอัปเดต state)
  UserModel copyWith({
    UserRole? role,
    String? token,
    TechnicianModel? technicianProfile,
    CustomerModel? customerProfile,
  }) {
    return UserModel(
      role: role ?? this.role,
      token: token ?? this.token,
      technicianProfile: technicianProfile ?? this.technicianProfile,
      customerProfile: customerProfile ?? this.customerProfile,
    );
  }
}
