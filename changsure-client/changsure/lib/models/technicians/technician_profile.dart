import 'tech_service.dart';
import 'tech_service_summary.dart';
import '../provinces/province.dart';
import '../badges/badge.dart';
class TechnicianProfile {
  final int id;
  final String firstname;
  final String lastname;
  final String bio;
  final String phone;
  final String email;
  final String avatarUrl;

  final double ratingAvg;
  final int ratingCount;
  final int totalJobs;

  final bool isAvailable;
  final bool isVerified;

  final List<ProvinceResponse> provinces;
  final List<TechServiceResponse> services;
  final List<TechServiceSummary> serviceSummary;
  final List<BadgeResponse> badges;

  TechnicianProfile({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.bio,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.totalJobs,
    required this.isAvailable,
    required this.isVerified,

    required this.provinces,
    required this.services,
    required this.serviceSummary,
    required this.badges,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    return TechnicianProfile(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      bio: json['bio'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      ratingAvg: (json['rating_avg'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      totalJobs: json['total_jobs'] ?? 0,
      isAvailable: json['is_available'] ?? false,
      isVerified: json['is_verified'] ?? false,

      provinces: (json["provinces"] as List<dynamic>? ?? [])
          .map((e) => ProvinceResponse.fromJson(e))
          .toList(),

      services: (json["services"] as List<dynamic>? ?? [])
          .map((e) => TechServiceResponse.fromJson(e))
          .toList(),

      serviceSummary: (json["service_summary"] as List<dynamic>? ?? [])
          .map((e) => TechServiceSummary.fromJson(e))
          .toList(),

      badges: (json["badges"] as List<dynamic>? ?? [])
          .map((e) => BadgeResponse.fromJson(e))
          .toList(),
    );
  }
}
