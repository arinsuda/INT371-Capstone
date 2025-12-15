import 'package:changsure/data/models/master_data_models.dart';
import 'package:changsure/data/models/address_model.dart';

class TechnicianModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? bio;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final double ratingAvg;
  final int ratingCount;
  final int totalJobs;
  final bool isAvailable;
  final bool isVerified;

  final List<ProvinceModel> provinces;
  final List<TechnicianService> services;
  final List<BadgeModel> badges;
  final List<AddressModel> addresses;

  TechnicianModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.bio,
    this.phone,
    this.email,
    this.avatarUrl,
    this.ratingAvg = 0.0,
    this.ratingCount = 0,
    this.totalJobs = 0,
    this.isAvailable = true,
    this.isVerified = false,
    this.provinces = const [],
    this.services = const [],
    this.badges = const [],
    this.addresses = const [],
  });

  String get fullName => '$firstName $lastName';

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['id'] ?? 0,
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      bio: json['bio'],
      phone: json['phone'],
      email: json['email'],
      avatarUrl: json['avatar_url'],

      // แปลงตัวเลข: JSON อาจมาเป็น int หรือ double ก็ได้
      ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] ?? 0,
      totalJobs: json['total_jobs'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      isVerified: json['is_verified'] ?? false,

      // แปลง Array ของข้อมูลย่อย
      provinces:
          (json['provinces'] as List<dynamic>?)
              ?.map((e) => ProvinceModel.fromJson(e))
              .toList() ??
          [],

      services:
          (json['services'] as List<dynamic>?)
              ?.map((e) => TechnicianService.fromJson(e))
              .toList() ??
          [],

      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => BadgeModel.fromJson(e))
              .toList() ??
          [],
      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((e) => AddressModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// Sub-Classes

class TechnicianService {
  final int serviceId;
  final String serviceName;
  final String categoryName;
  final String pricingType; // 'FIXED' or 'RANGE'
  final double? priceFixed;
  final double? priceMin;
  final double? priceMax;

  TechnicianService({
    required this.serviceId,
    required this.serviceName,
    required this.categoryName,
    required this.pricingType,
    this.priceFixed,
    this.priceMin,
    this.priceMax,
  });

  factory TechnicianService.fromJson(Map<String, dynamic> json) {
    return TechnicianService(
      serviceId: json['service_id'] ?? 0,
      serviceName: json['service_name'] ?? '',
      categoryName: json['category_name'] ?? '',
      pricingType: json['pricing_type'] ?? 'FIXED',
      priceFixed: (json['price_fixed'] as num?)?.toDouble(),
      priceMin: (json['price_min'] as num?)?.toDouble(),
      priceMax: (json['price_max'] as num?)?.toDouble(),
    );
  }
}

class BadgeModel {
  final int id;
  final String name;
  final String iconUrl;
  final String description;

  BadgeModel({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.description,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      description: json['description'] ?? '',
    );
  }
}
