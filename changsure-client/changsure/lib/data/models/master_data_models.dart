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
  final int provinceId;

  SubDistrictModel({
    required this.id,
    required this.nameTh,
    required this.postalCode,
    required this.districtId,
    required this.provinceId,
  });

  factory SubDistrictModel.fromJson(Map<String, dynamic> json) {
    return SubDistrictModel(
      id: json['id'] ?? 0,
      nameTh: json['name_th'] ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      districtId: json['district_id'] ?? 0,
      provinceId: json['province_id'] ?? 0,
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
  final bool isActive;
  final String? categoryName;

  final bool available;
  final String priceSource;
  final int technicianCount;

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
    this.isActive = true,
    this.categoryName,
    this.available = true,
    this.priceSource = 'default',
    this.technicianCount = 0,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      serName: json['ser_name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      serDescription: json['ser_description'],
      serDetails: List<String>.from(json['ser_details'] ?? []),

      imageUrls: json['image_urls'] != null
          ? List<String>.from(json['image_urls'])
          : (json['thumbnail_url'] != null ? [json['thumbnail_url']] : []),
      workingDuration: List<String>.from(json['working_duration'] ?? []),
      additionalTerms: List<String>.from(json['additional_terms'] ?? []),
      defaultPrice: ServicePrice.fromJson(
        json['price'] ?? json['default_price'] ?? {},
      ),
      isActive: json['is_active'] ?? true,
      categoryName: json['category_name'],
      available: json['available'] ?? true,
      priceSource: json['price_source'] ?? 'default',
      technicianCount: json['technician_count'] ?? 0,
    );
  }
}

class ServicePrice {
  final double? min;
  final double? max;
  final double? value;
  final String? type;

  ServicePrice({this.min, this.max, this.value, this.type});

  factory ServicePrice.fromJson(Map<String, dynamic> json) {
    toDouble(v) => v == null ? null : (v as num).toDouble();
    return ServicePrice(
      min: toDouble(json['min']),
      max: toDouble(json['max']),
      value: toDouble(json['value']),
      type: json['type'],
    );
  }

  double get startingPrice => min ?? value ?? 0;

  String get displayText {
    if (type == 'fixed' || max == null) {
      return '฿${startingPrice.toStringAsFixed(0)}';
    }
    return '฿${startingPrice.toStringAsFixed(0)} - ฿${max!.toStringAsFixed(0)}';
  }
}

class ServiceCategoryModel {
  final int id;
  final String catName;
  final String? catDesc;
  final String? iconUrl;
  final bool isActive;
  final List<ServiceModel> services;

  ServiceCategoryModel({
    required this.id,
    required this.catName,
    this.catDesc,
    this.iconUrl,
    this.isActive = true,
    this.services = const [],
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    final categoryId = json['category_id'] ?? json['id'] ?? 0; // 👈 ดึง id ก่อน

    final services =
        (json['services'] as List?)?.map((e) {
          final serviceJson = Map<String, dynamic>.from(e);
          serviceJson['category_id'] =
              categoryId; // 👈 inject เข้าไปทุก service
          return ServiceModel.fromJson(serviceJson);
        }).toList() ??
        [];

    return ServiceCategoryModel(
      id: categoryId,
      catName: json['category_name'] ?? json['cat_name'] ?? '',
      catDesc: json['cat_desc'],
      iconUrl: json['category_icon'] ?? json['icon_url'],
      isActive: json['is_active'] ?? true,
      services: services,
    );
  }

  ServiceCategoryModel copyWith({
    List<ServiceModel>? services,
    String? catDesc,
    String? iconUrl,
    bool? isActive,
  }) {
    return ServiceCategoryModel(
      id: id,
      catName: catName,
      catDesc: catDesc ?? this.catDesc,
      iconUrl: iconUrl ?? this.iconUrl,
      isActive: isActive ?? this.isActive,
      services: services ?? this.services,
    );
  }
}

class TechnicianQuery {
  final int serviceId;
  final int provinceId;

  const TechnicianQuery({required this.serviceId, required this.provinceId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechnicianQuery &&
          serviceId == other.serviceId &&
          provinceId == other.provinceId;

  @override
  int get hashCode => serviceId.hashCode ^ provinceId.hashCode;
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
      categoryName: json['category_name'] ?? '',
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

class DocumentTermResponse {
  final String slug;
  final int version;
  final String locale;
  final DateTime updatedAt;
  final DocumentContent content;

  DocumentTermResponse({
    required this.slug,
    required this.version,
    required this.locale,
    required this.updatedAt,
    required this.content,
  });

  factory DocumentTermResponse.fromJson(Map<String, dynamic> json) {
    return DocumentTermResponse(
      slug: json['slug'],
      version: json['version'],
      locale: json['locale'],
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      content: DocumentContent.fromJson(json['content']),
    );
  }
}

class DocumentContent {
  final String body;
  final List<DocumentConsent> consents;

  DocumentContent({required this.body, required this.consents});

  factory DocumentContent.fromJson(Map<String, dynamic> json) {
    return DocumentContent(
      body: json['body'] ?? '',
      consents: (json['consents'] as List<dynamic>? ?? [])
          .map((e) => DocumentConsent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DocumentConsent {
  final String key;
  final String label;
  final bool required;
  final String description;

  DocumentConsent({
    required this.key,
    required this.label,
    required this.required,
    required this.description,
  });

  factory DocumentConsent.fromJson(Map<String, dynamic> json) {
    return DocumentConsent(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      required: json['required'] ?? false,
      description: json['description'] ?? '',
    );
  }
}

class DocumentAcceptanceRequest {
  final int userId;
  final String role;
  final List<String> consents;

  DocumentAcceptanceRequest({
    required this.userId,
    required this.role,
    required this.consents,
  });

  Map<String, dynamic> toJson() {
    return {"user_id": userId, "role": role, "consents": consents};
  }
}

class DocumentAcceptanceResponse {
  final String id;
  final int userId;
  final String userRole;
  final String documentId;
  final int version;
  final DateTime acceptedAt;
  final String locale;
  final List<String> consents;

  DocumentAcceptanceResponse({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.documentId,
    required this.version,
    required this.acceptedAt,
    required this.locale,
    required this.consents,
  });

  factory DocumentAcceptanceResponse.fromJson(Map<String, dynamic> json) {
    return DocumentAcceptanceResponse(
      id: json["id"],
      userId: json["user_id"],
      userRole: json["user_role"],
      documentId: json["document_id"],
      version: json["version"],
      acceptedAt: DateTime.parse(json["accepted_at"]),
      locale: json["locale"],
      consents: List<String>.from(json["consents"]),
    );
  }
}
