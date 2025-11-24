import '../service_categories/service_category.dart';

class ServiceResponse {
  final int id;
  final String serName;
  final String? serDescription;
  final String? imageUrl;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  final int categoryId;
  final ServiceCategory? category;

  ServiceResponse({
    required this.id,
    required this.serName,
    this.serDescription,
    this.imageUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    required this.categoryId,
    this.category,
  });

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    return ServiceResponse(
      id: _i(json["id"]),
      serName: json["ser_name"] ?? "",
      serDescription: json["ser_description"],
      imageUrl: json["image_url"],
      isActive: json["is_active"] ?? true,
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
      categoryId: _i(json["category_id"]),
      category: json["category"] != null
          ? ServiceCategory.fromJson(json["category"])
          : null,
    );
  }

  static int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
}
