import 'package:changsure/data/models/address_model.dart';
import 'package:changsure/data/models/technician/technician_model.dart';
import 'package:changsure/data/models/customer/customer_model.dart';

// Enum เพื่อแยกสถานะ
enum UserRole { technician, customer, guest }

class UserModel {
  final int id;
  final String email;
  final UserRole role;
  final String? token;

  final TechnicianModel? technicianProfile;
  final CustomerModel? customerProfile;

  final List<AddressModel> addresses;

  UserModel({
    this.id = 0,
    this.email = '',
    required this.role,
    this.token,
    this.technicianProfile,
    this.customerProfile,
    this.addresses = const [],
  });

  bool get isAuthenticated => token != null;

  String get fullName {
    if (role == UserRole.technician) {
      return technicianProfile?.fullName ?? 'Unknown Technician';
    } else if (role == UserRole.customer) {
      return customerProfile?.fullName ?? 'Unknown Customer';
    }
    return 'Guest';
  }

  String? get avatarUrl {
    if (role == UserRole.technician) return technicianProfile?.avatarUrl;
    if (role == UserRole.customer) return customerProfile?.avatarUrl;
    return null;
  }

  UserModel copyWith({
    int? id,
    String? email,
    UserRole? role,
    String? token,
    TechnicianModel? technicianProfile,
    CustomerModel? customerProfile,
    List<AddressModel>? addresses,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      technicianProfile: technicianProfile ?? this.technicianProfile,
      customerProfile: customerProfile ?? this.customerProfile,
      addresses: addresses ?? this.addresses,
    );
  }
}
