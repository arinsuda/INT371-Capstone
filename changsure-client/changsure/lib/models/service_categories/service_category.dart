class ServiceCategoryModel {
  final int id;
  final String catName;
  final String? catDesc;
  final String? iconUrl;
  final bool isActive;

  ServiceCategoryModel({
    required this.id,
    required this.catName,
    this.catDesc,
    this.iconUrl,
    required this.isActive,
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: _parseInt(json["id"]),
      catName: json["cat_name"] ?? "-",
      catDesc: json["cat_desc"],
      iconUrl: json["icon_url"],
      isActive: json["is_active"] ?? true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
