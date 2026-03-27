import 'dart:io';

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
  final List<ServiceSummary> serviceSummary;

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
    this.serviceSummary = const [],
  });

  String get fullName => '$firstName $lastName';

  TechnicianModel copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? bio,
    String? phone,
    String? email,
    String? avatarUrl,
    double? ratingAvg,
    int? ratingCount,
    int? totalJobs,
    bool? isAvailable,
    bool? isVerified,
    List<ProvinceModel>? provinces,
    List<TechnicianService>? services,
    List<BadgeModel>? badges,
    List<AddressModel>? addresses,
    List<ServiceSummary>? serviceSummary,
  }) {
    return TechnicianModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      totalJobs: totalJobs ?? this.totalJobs,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      provinces: provinces ?? this.provinces,
      services: services ?? this.services,
      badges: badges ?? this.badges,
      addresses: addresses ?? this.addresses,
      serviceSummary: serviceSummary ?? this.serviceSummary,
    );
  }

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
      serviceSummary:
          (json['service_summary'] as List<dynamic>?)
              ?.map((e) => ServiceSummary.fromJson(e))
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

  Future<dynamic> updateProfile({
    required String token,
    required String firstName,
    required String lastName,
    required String phone,
    String? bio,
    List<int>? provinceIds,
    List<Map<String, dynamic>>? services,
    File? avatarFile,
  }) async {}
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

class ServiceSummary {
  final int? serviceCategoryId;
  final String? serviceCategoryName;
  final List<ServiceItem>? services;

  ServiceSummary({
    this.serviceCategoryId,
    this.serviceCategoryName,
    this.services,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> json) {
    return ServiceSummary(
      serviceCategoryId: json['service_category_id'],
      serviceCategoryName: json['service_category_name'],
      services: json['services'] != null
          ? (json['services'] as List)
                .map((i) => ServiceItem.fromJson(i))
                .toList()
          : null,
    );
  }
}

class ServiceItem {
  final int? serviceId;
  final String? serviceName;

  ServiceItem({this.serviceId, this.serviceName});

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      serviceId: json['service_id'],
      serviceName: json['service_name'],
    );
  }
}

class VerifyTechnician {
  final String? verifyStatus;

  VerifyTechnician({required this.verifyStatus});

  factory VerifyTechnician.fromJson(Map<String, dynamic> json) {
    return VerifyTechnician(verifyStatus: json['verify_status'] as String?);
  }
}

class ReviewImage {
  final String imageUrl;

  ReviewImage({
    required this.imageUrl,
  });

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      imageUrl: json['image_url'] ?? '',
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String avatar;

  Customer({
    required this.id,
    required this.name,
    required this.avatar,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }
}

class Service {
  final int id;
  final String name;
  final String price;
  final String picture;
  final int categoryId;
  final String categoryName;

  Service({
    required this.id,
    required this.name,
    required this.price,
    required this.picture,
    required this.categoryId,
    required this.categoryName,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'] ?? '',
      price: json['price'] ?? '',
      picture: json['picture'] ?? '',
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? '',
    );
  }
}

class Review {
  final int id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final Customer customer;
  final Service service;
  final List<ReviewImage> images;

  Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.customer,
    required this.service,
    required this.images,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      rating: json['rating'],
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      customer: Customer.fromJson(json['customer']),
      service: Service.fromJson(json['service']),
      images: (json['images'] as List)
          .map((e) => ReviewImage.fromJson(e))
          .toList(),
    );
  }
}

class ReviewSummary {
  final double avgRating;
  final int totalReviews;
  final Map<String, int> breakdown;

  ReviewSummary({
    required this.avgRating,
    required this.totalReviews,
    required this.breakdown,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      avgRating: (json['avg_rating'] as num).toDouble(),
      totalReviews: json['total_reviews'],
      breakdown: Map<String, int>.from(json['breakdown']),
    );
  }
}

class Meta {
  final int limit;
  final int page;
  final int total;

  Meta({
    required this.limit,
    required this.page,
    required this.total,
  });

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      limit: json['limit'],
      page: json['page'],
      total: json['total'],
    );
  }
}

class ReviewData {
  final List<Review> reviews;
  final ReviewSummary summary;

  ReviewData({
    required this.reviews,
    required this.summary,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    return ReviewData(
      reviews: (json['reviews'] as List)
          .map((e) => Review.fromJson(e))
          .toList(),
      summary: ReviewSummary.fromJson(json['summary']),
    );
  }
}

class ReviewResponse {
  final ReviewData data;
  final Meta meta;
  final bool success;

  ReviewResponse({
    required this.data,
    required this.meta,
    required this.success,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      data: ReviewData.fromJson(json['data']),
      meta: Meta.fromJson(json['meta']),
      success: json['success'],
    );
  }
}
