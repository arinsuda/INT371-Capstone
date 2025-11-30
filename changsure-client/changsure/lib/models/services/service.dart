class ServiceModel {
  final int id;
  final String serName;
  final String? serDescription;
  final List<String> serDetails;
  final List<String> additionalTerms;
  final List<String> workingDuration;
  final List<String> imageUrls;

  final int? categoryId;
  final String? categoryName;

  final Map<String, dynamic>? defaultPrice;

  ServiceModel({
    required this.id,
    required this.serName,
    this.serDescription,
    required this.serDetails,
    required this.additionalTerms,
    required this.workingDuration,
    required this.imageUrls,
    this.categoryId,
    this.categoryName,
    this.defaultPrice,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: (json["id"] ?? 0) is int
          ? json["id"]
          : int.tryParse(json["id"].toString()) ?? 0,

      serName: json["ser_name"] ?? "-",
      serDescription: json["ser_description"],

      serDetails: (json["ser_details"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),

      additionalTerms: (json["additional_terms"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),

      workingDuration: (json["working_duration"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),

      imageUrls: (json["image_urls"] as List? ?? [])
          .map((e) => e.toString())
          .toList(),

      categoryId: json["category_id"] == null
          ? null
          : (json["category_id"] is int
                ? json["category_id"]
                : int.tryParse(json["category_id"].toString())),

      categoryName: json["category_name"],

      defaultPrice: json["default_price"],
    );
  }
}
