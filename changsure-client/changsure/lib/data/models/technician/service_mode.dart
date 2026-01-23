class TechnicianServiceModel {
  final int serviceId;
  final String serviceName;
  final int categoryId;
  final String pricingType;
  final int? priceFixed;
  final int? priceMin;
  final int? priceMax;

  TechnicianServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.categoryId,
    required this.pricingType,
    this.priceFixed,
    this.priceMin,
    this.priceMax,
  });

  factory TechnicianServiceModel.fromJson(Map<String, dynamic> json) {
    return TechnicianServiceModel(
      serviceId: json['service_id'] ?? 0,
      serviceName: json['service_name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      pricingType: json['pricing_type'] ?? 'FIXED',
      priceFixed: json['price_fixed'],
      priceMin: json['price_min'],
      priceMax: json['price_max'],
    );
  }
}