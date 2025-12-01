import 'package:changsure/helpers/safe_types.dart';
import 'tech_service.dart';

class TechServiceSummary {
  final int serviceCategoryId;
  final String serviceCategoryName;
  final List<TechServiceResponse> services;

  TechServiceSummary({
    required this.serviceCategoryId,
    required this.serviceCategoryName,
    required this.services,
  });

  factory TechServiceSummary.fromJson(Map<String, dynamic> json) {
    return TechServiceSummary(
      serviceCategoryId: safeInt(
        json["service_category_id"],
        field: "service_category_id",
      ),
      serviceCategoryName: safeString(
        json["service_category_name"],
        field: "service_category_name",
      ),
      services: (json["services"] is List)
          ? (json["services"] as List)
                .map((e) => TechServiceResponse.fromJson(e))
                .toList()
          : [],
    );
  }
}
