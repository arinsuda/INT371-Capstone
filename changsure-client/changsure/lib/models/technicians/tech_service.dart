class TechServiceResponse {
  final int serviceId;
  final String serviceName;
  final int? categoryId;
  final String? categoryName;
  final String pricingType;
  final double? priceFixed;
  final double? priceMin;
  final double? priceMax;

  TechServiceResponse({
    required this.serviceId,
    required this.serviceName,
    this.categoryId,
    this.categoryName,
    required this.pricingType,
    this.priceFixed,
    this.priceMin,
    this.priceMax,
  });

  factory TechServiceResponse.fromJson(Map<String, dynamic> json) {
    return TechServiceResponse(
      serviceId: _jsonInt(json["service_id"]),
      serviceName: json["service_name"] ?? "",
      categoryId: (json["category_id"] as num?)?.toInt(),
      categoryName: json["category_name"],
      pricingType: json["pricing_type"] ?? "",
      priceFixed: _jsonDouble(json["price_fixed"]),
      priceMin: _jsonDouble(json["price_min"]),
      priceMax: _jsonDouble(json["price_max"]),
    );
  }

  static int _jsonInt(dynamic v) => (v as num?)?.toInt() ?? 0;
  static double? _jsonDouble(dynamic v) => (v as num?)?.toDouble();
}
