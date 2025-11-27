class TechServiceSummary {
  final int serviceId;
  final String serviceName;
  final int total;

  TechServiceSummary({
    required this.serviceId,
    required this.serviceName,
    required this.total,
  });

  factory TechServiceSummary.fromJson(Map<String, dynamic> json) {
    return TechServiceSummary(
      serviceId: json["service_id"],
      serviceName: json["service_name"],
      total: json["total"] ?? 0,
    );
  }
}
