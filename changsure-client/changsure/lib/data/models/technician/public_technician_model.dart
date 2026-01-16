import 'public_post_model.dart';

class PublicTechnicianProfile {
  final int id;
  final String firstName;
  final String lastName;
  final String? bio;
  final String? avatarUrl;
  final double? ratingAvg;
  final int ratingCount;
  final int totalJobs;
  final bool isAvailable;
  final bool isVerified;
  final List<Province> provinces;
  final List<TechService> services;
  final List<ServiceSummary> serviceSummary;
  final List<Badge> badges;
  final List<PublicPost> posts;

  PublicTechnicianProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.bio,
    this.avatarUrl,
    this.ratingAvg,
    required this.ratingCount,
    required this.totalJobs,
    required this.isAvailable,
    required this.isVerified,
    required this.provinces,
    required this.services,
    required this.serviceSummary,
    required this.badges,
    required this.posts,
  });

  factory PublicTechnicianProfile.fromJson(Map<String, dynamic> json) {
    final techId = (json['id'] ?? 0) as int;

    return PublicTechnicianProfile(
      id: techId,
      firstName: (json['firstname'] as String?) ?? '',
      lastName: (json['lastname'] as String?) ?? '',
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(), // ✅ fix
      ratingCount: (json['rating_count'] ?? 0) as int,
      totalJobs: (json['total_jobs'] ?? 0) as int,
      isAvailable: (json['is_available'] ?? false) as bool,
      isVerified: (json['is_verified'] ?? false) as bool,
      provinces:
          (json['provinces'] as List?)
              ?.map((e) => Province.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      services:
          (json['services'] as List?)
              ?.map((e) => TechService.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      serviceSummary:
          (json['service_summary'] as List?)
              ?.map((e) => ServiceSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      badges:
          (json['badges'] as List?)
              ?.map((e) => Badge.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      posts:
          (json['posts'] as List?)
              ?.map(
                (e) => PublicPost.fromJson({
                  ...e as Map<String, dynamic>,
                  'technician_id': techId,
                }),
              )
              .toList() ??
          [],
    );
  }

  String get fullName => '$firstName $lastName';
  int get recentPostsCount => posts.length;
}

class Province {
  final int id;
  final String nameTh;

  Province({required this.id, required this.nameTh});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: (json['id'] ?? 0) as int,
      nameTh: (json['name_th'] as String?) ?? '',
    );
  }
}

class TechService {
  final int serviceId;
  final String serviceName;
  final int? categoryId;
  final String? categoryName;
  final String pricingType;
  final double? priceFixed;
  final double? priceMin;
  final double? priceMax;

  TechService({
    required this.serviceId,
    required this.serviceName,
    this.categoryId,
    this.categoryName,
    required this.pricingType,
    this.priceFixed,
    this.priceMin,
    this.priceMax,
  });

  factory TechService.fromJson(Map<String, dynamic> json) {
    return TechService(
      serviceId: (json['service_id'] ?? 0) as int,
      serviceName: (json['service_name'] as String?) ?? '',
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      pricingType: (json['pricing_type'] as String?) ?? '',
      priceFixed: (json['price_fixed'] as num?)?.toDouble(),
      priceMin: (json['price_min'] as num?)?.toDouble(),
      priceMax: (json['price_max'] as num?)?.toDouble(),
    );
  }
}

class ServiceSummary {
  final int serviceCategoryId;
  final String serviceCategoryName;
  final List<ServiceItem> services;

  ServiceSummary({
    required this.serviceCategoryId,
    required this.serviceCategoryName,
    required this.services,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> json) {
    return ServiceSummary(
      serviceCategoryId: (json['service_category_id'] ?? 0) as int,
      serviceCategoryName: (json['service_category_name'] as String?) ?? '',
      services:
          (json['services'] as List?)
              ?.map((e) => ServiceItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ServiceItem {
  final int serviceId;
  final String serviceName;

  ServiceItem({required this.serviceId, required this.serviceName});

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceId: (json['service_id'] ?? 0) as int,
      serviceName: (json['service_name'] as String?) ?? '',
    );
  }
}

class Badge {
  final int id;
  final String name;
  final String? description;
  final String iconUrl;

  Badge({
    required this.id,
    required this.name,
    this.description,
    required this.iconUrl,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      iconUrl: (json['icon_url'] as String?) ?? '', // ✅ fix
    );
  }
}
