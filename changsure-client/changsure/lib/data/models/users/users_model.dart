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

class CustomerRegisterModel {
  final String email;
  final String password;
  final String confirmPassword;
  final String firstname;
  final String lastname;
  final String phone;
  final RegisterAddressModel address;

  CustomerRegisterModel({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.firstname,
    required this.lastname,
    required this.phone,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
      "confirm_password": confirmPassword,
      "firstname": firstname,
      "lastname": lastname,
      "phone": phone,
      "address": address.toJson(),
    };
  }
}

class TechnicianServiceModel {
  final int serviceId;
  final String pricingType;
  final double? priceFixed;
  final double? priceMin;
  final double? priceMax;

  TechnicianServiceModel({
    required this.serviceId,
    required this.pricingType,
    this.priceFixed,
    this.priceMin,
    this.priceMax,
  });

  Map<String, dynamic> toJson() {
    return {
      "service_id": serviceId,
      "pricing_type": pricingType,
      "price_fixed": priceFixed,
      "price_min": priceMin,
      "price_max": priceMax,
    };
  }
}

class TechnicianRegisterModel {
  final String email;
  final String password;
  final String confirmPassword;
  final String firstname;
  final String lastname;
  final String phone;
  final List<String>? consents;
  final RegisterAddressModel address;
  final List<TechnicianServiceModel> services;
  final List<int>? provinceIds;

  TechnicianRegisterModel({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.firstname,
    required this.lastname,
    required this.phone,
    required this.address,
    required this.services,
    required this.provinceIds,
    required this.consents
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
      "confirm_password": confirmPassword,
      "firstname": firstname,
      "lastname": lastname,
      "phone": phone,
      "address": address.toJson(),
      "services": services.map((e) => e.toJson()).toList(),
      "province_ids": provinceIds,
      "consents" : consents
    };
  }
}

class RegisterAddressModel {
  final String label;
  final String? phoneNumber;
  final String addressLine;
  final int subDistrictId;
  final int districtId;
  final int provinceId;
  final double latitude;
  final double longitude;
  final bool isPrimary;

  RegisterAddressModel({
    required this.label,
    this.phoneNumber,
    required this.addressLine,
    required this.subDistrictId,
    required this.districtId,
    required this.provinceId,
    required this.latitude,
    required this.longitude,
    required this.isPrimary,
  });

  Map<String, dynamic> toJson() {
    final map = {
      "label": label,
      "address_line": addressLine,
      "sub_district_id": subDistrictId,
      "district_id": districtId,
      "province_id": provinceId,
      "latitude": latitude,
      "longitude": longitude,
      "is_primary": isPrimary,
    };

    if (phoneNumber != null && phoneNumber!.isNotEmpty) {
      map["phone_number"] = phoneNumber!;
    }

    return map;
  }
}

class OTPResponse {
  final String message;
  final int expiresIn;
  final String otp;

  OTPResponse({
    required this.message,
    required this.expiresIn,
    required this.otp,
  });

  factory OTPResponse.fromJson(Map<String, dynamic> json) {
    return OTPResponse(
      message: json['message'],
      expiresIn: json['expires_in'],
      otp: json['otp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'expires_in': expiresIn,
      'otp': otp,
    };
  }
}

class VerifyOTPRequest {
  final String email;
  final String otp;

  VerifyOTPRequest({
    required this.email,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "otp": otp,
    };
  }
}

class VerifyOTPResponse {
  final String message;
  final String resetToken;

  VerifyOTPResponse({
    required this.message,
    required this.resetToken,
  });

  factory VerifyOTPResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOTPResponse(
      message: json['message'],
      resetToken: json['reset_token'],
    );
  }
}

class ResetPasswordRequest {
  final String resetToken;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordRequest({
    required this.resetToken,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      "reset_token": resetToken,
      "new_password": newPassword,
      "confirm_password": confirmPassword,
    };
  }
}

class ResetPasswordResponse {
  final String message;

  ResetPasswordResponse({
    required this.message,
  });

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(
      message: json["message"],
    );
  }
}
