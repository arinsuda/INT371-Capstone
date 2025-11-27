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
    final data = json['data'] ?? {};

    return TechnicianProfile(
      technician: Technician.fromJson(data),
      provinces: (data['provinces'] as List? ?? [])
          .map((e) => ProvinceResponse.fromJson(e))
          .toList(),
      services: (data['services'] as List? ?? [])
          .map((e) => TechServiceResponse.fromJson(e))
          .toList(),
      serviceSummary: (data['service_summary'] as List? ?? [])
          .map((e) => TechServiceSummary.fromJson(e))
          .toList(),
      badges: (data['badges'] as List? ?? [])
          .map((e) => BadgeResponse.fromJson(e))
          .toList(),
    );
  }
}
