class ServiceCategory {
  final int id;
  final String catName;
  final String? catDesc;
  final String? iconUrl;
  final bool isActive;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  ServiceCategory({
    required this.id,
    required this.catName,
    this.catDesc,
    this.iconUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: _int(json["id"]),
      catName: json["cat_name"] ?? "",
      catDesc: json["cat_description"],
      iconUrl: json["icon_url"],
      isActive: json["is_active"] ?? true,
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
      deletedAt: json["deleted_at"],
    );
  }

  static int _int(dynamic v) => (v as num?)?.toInt() ?? 0;
}
