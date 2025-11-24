import 'technician.dart';
import 'tech_service.dart';
import 'tech_service_summary.dart';

import '../provinces/province.dart'; 
import '../badges/badge.dart';

class TechnicianProfile {
  final Technician technician;

  final List<ProvinceResponse> provinces;
  final List<TechServiceResponse> services;
  final List<TechServiceSummary> serviceSummary;
  final List<BadgeResponse> badges;

  TechnicianProfile({
    required this.technician,
    required this.provinces,
    required this.services,
    required this.serviceSummary,
    required this.badges,
  });

  factory TechnicianProfile.fromJson(Map<String, dynamic> json) {
    return TechnicianProfile(
      technician: Technician.fromJson(json),
      provinces: (json["provinces"] as List? ?? [])
          .map((e) => ProvinceResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (json["services"] as List? ?? [])
          .map((e) => TechServiceResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      serviceSummary: (json["service_summary"] as List? ?? [])
          .map((e) => TechServiceSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      badges: (json["badges"] as List? ?? [])
          .map((e) => BadgeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
