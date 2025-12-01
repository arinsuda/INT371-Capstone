import 'tech_service.dart';
import 'tech_service_summary.dart';
import '../provinces/province.dart';
import '../badges/badge.dart';

int safeInt(dynamic v, {String? field}) {
  if (v == null) {
    throw Exception("❌ Field '$field' is NULL but expected int.");
  }
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    return int.tryParse(v) ??
        (throw Exception("❌ Field '$field' cannot parse '$v' to int."));
  }
  throw Exception("❌ Field '$field' invalid type: ${v.runtimeType}");
}

double safeDouble(dynamic v, {String? field}) {
  if (v == null) {
    return 0.0;
  }
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) {
    return double.tryParse(v) ??
        (throw Exception("❌ Field '$field' cannot parse '$v' to double."));
  }
  throw Exception("❌ Field '$field' invalid type: ${v.runtimeType}");
}

String safeString(dynamic v, {String? field}) {
  if (v == null) {
    return "";
  }
  return v.toString();
}

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
    try {
      return TechnicianProfile(
        id: safeInt(json['id'], field: "id"),
        firstname: safeString(json['firstname'], field: "firstname"),
        lastname: safeString(json['lastname'], field: "lastname"),
        bio: safeString(json['bio'], field: "bio"),
        phone: safeString(json['phone'], field: "phone"),
        email: safeString(json['email'], field: "email"),
        avatarUrl: safeString(json['avatar_url'], field: "avatar_url"),

        ratingAvg: safeDouble(json['rating_avg'], field: "rating_avg"),
        ratingCount: safeInt(json['rating_count'], field: "rating_count"),
        totalJobs: safeInt(json['total_jobs'], field: "total_jobs"),

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
    } catch (e, stack) {
      throw Exception(
        "❌ TechnicianProfile parsing error:\n$e\n\nJSON => $json\n\nSTACK => $stack",
      );
    }
  }
}
