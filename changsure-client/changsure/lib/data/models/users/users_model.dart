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

  String? get phone {
    if (role == UserRole.technician) return technicianProfile?.phone;
    if (role == UserRole.customer) return customerProfile?.phone;
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

  List<AddressModel> get allAddresses {
    if (role == UserRole.technician) {
      return technicianProfile?.addresses ?? [];
    }
    return addresses;
  }
}

class RegisterModel {
  final String email;
  final String password;
  final String confirmPassword;
  final String role;

  RegisterModel({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.role,
  });

  /// 🔥 ใช้ส่งไป backend
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'confirm_password': confirmPassword,
      'role': role,
    };
  }

  /// 🔄 ใช้กรณี backend ส่งกลับมา (ถ้ามี)
  factory RegisterModel.fromJson(Map<String, dynamic> json) {
    return RegisterModel(
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      confirmPassword: json['confirm_password'] ?? '',
      role: json['role'] ?? '',
    );
  }

  /// 🧠 optional: copyWith ไว้แก้ค่าแบบ immutable
  RegisterModel copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? role,
  }) {
    return RegisterModel(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      role: role ?? this.role,
    );
  }
}
