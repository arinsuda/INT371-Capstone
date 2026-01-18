import 'package:flutter/cupertino.dart';

class ProvinceModel {
  final int id;
  final String nameTh;

  ProvinceModel({required this.id, required this.nameTh});

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(id: json['id'], nameTh: json['name_th']);
  }
}

class DistrictModel {
  final int id;
  final String nameTh;
  final int provinceId;

  DistrictModel({
    required this.id,
    required this.nameTh,
    required this.provinceId,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      id: json['id'] ?? 0,
      nameTh: json['name_th'] ?? '',
      provinceId: json['province_id'] ?? 0,
    );
  }
}

class SubDistrictModel {
  final int id;
  final String nameTh;
  final String postalCode;
  final int districtId;

  SubDistrictModel({
    required this.id,
    required this.nameTh,
    required this.postalCode,
    required this.districtId,
  });

  factory SubDistrictModel.fromJson(Map<String, dynamic> json) {
    return SubDistrictModel(
      id: json['id'] ?? 0,
      nameTh: json['name_th'] ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      districtId: json['district_id'] ?? 0,
    );
  }
}

class ServiceCategoryModel {
  final int id;
  final String catName;
  final List<ServiceModel> services;

  ServiceCategoryModel({
    required this.id,
    required this.catName,
    this.services = const [],
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'],
      catName: json['cat_name'],
      services: [],
    );
  }

  ServiceCategoryModel copyWith({List<ServiceModel>? services}) {
    return ServiceCategoryModel(
      id: id,
      catName: catName,
      services: services ?? this.services,
    );
  }
}

class ServiceModel {
  final int id;
  final String serName;
  final int categoryId;
  final String? serDescription;
  final List<String> serDetails;
  final List<String> imageUrls;
  final List<String> workingDuration;
  final List<String> additionalTerms;
  final ServicePrice defaultPrice;

  ServiceModel({
    required this.id,
    required this.serName,
    required this.categoryId,
    this.serDescription,
    this.serDetails = const [],
    this.imageUrls = const [],
    this.workingDuration = const [],
    this.additionalTerms = const [],
    required this.defaultPrice,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      serName: json['ser_name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      serDescription: json['ser_description'],
      serDetails: List<String>.from(json['ser_details'] ?? []),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      workingDuration: List<String>.from(json['working_duration'] ?? []),
      additionalTerms: List<String>.from(json['additional_terms'] ?? []),
      defaultPrice: ServicePrice.fromJson(json['default_price'] ?? {}),
    );
  }
}

class ServicePrice {
  final int? min;
  final int? max;
  final int? value;
  final String? type;

  ServicePrice({this.min, this.max, this.value, this.type});

  factory ServicePrice.fromJson(Map<String, dynamic> json) {
    return ServicePrice(
      min: json['min'],
      max: json['max'],
      value: json['value'],
      type: json['type'],
    );
  }
}

class TechnicianQuery {
  final int serviceId;
  final int provinceId;

  TechnicianQuery({required this.serviceId, required this.provinceId});
}

class BadgeModel {
  final int id;
  final String name;
  final String description;
  final String iconUrl;
  final int level;
  final bool isActive;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.level,
    required this.isActive,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      level: json['level'] ?? 0,
      isActive: json['is_active'] ?? false,
    );
  }
}

class Technician {
  final int id;
  final String firstname;
  final String lastname;
  final String? avatarUrl;
  final int priceMin;
  final int priceMax;
  final int? ratingAvg;
  final int? ratingCount;
  final double distanceKm;
  final List<BadgeModel> badges;
  final int totalJobs;
  final String categoryName;

  Technician({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.avatarUrl,
    required this.priceMin,
    required this.priceMax,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.distanceKm = 0.0,
    this.badges = const [],
    this.totalJobs = 0,
    required this.categoryName,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      avatarUrl: json['avatar_url'],
      priceMin: json['price_min'] ?? 0,
      priceMax: json['price_max'] ?? 0,
      ratingAvg: json['rating_avg'] ?? 0,
      ratingCount: json['rating_count'] ?? 0,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      badges:
          (json['badges'] as List?)
              ?.map((e) => BadgeModel.fromJson(e))
              .toList() ??
          [],
      totalJobs: json['total_jobs'] ?? 0,
      categoryName: json['category_name'],
    );
  }
}

@immutable
class AutoSelectTechnicianQuery {
  final int serviceId;
  final int provinceId;
  final int? minPrice;
  final int? maxPrice;

  const AutoSelectTechnicianQuery({
    required this.serviceId,
    required this.provinceId,
    this.minPrice,
    this.maxPrice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutoSelectTechnicianQuery &&
          serviceId == other.serviceId &&
          provinceId == other.provinceId &&
          minPrice == other.minPrice &&
          maxPrice == other.maxPrice;

  @override
  int get hashCode =>
      serviceId.hashCode ^
      provinceId.hashCode ^
      minPrice.hashCode ^
      maxPrice.hashCode;
}
