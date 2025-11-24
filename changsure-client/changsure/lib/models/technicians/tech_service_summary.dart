class TechServiceSummary {
  final int serviceId;
  final String serviceName;

  TechServiceSummary({required this.serviceId, required this.serviceName});

  factory TechServiceSummary.fromJson(Map<String, dynamic> json) {
    return TechServiceSummary(
      serviceId: _jsonInt(json["service_id"]),
      serviceName: json["service_name"] ?? "",
    );
  }

  static int _jsonInt(dynamic v) => (v as num?)?.toInt() ?? 0;
}
