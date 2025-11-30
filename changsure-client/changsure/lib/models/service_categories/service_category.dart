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
      id: (json["ID"] ?? 0) is int
          ? json["ID"]
          : int.tryParse(json["ID"].toString()) ?? 0,

      catName: json["CatName"] ?? "-",
      catDesc: json["CatDesc"],
      iconUrl: json["IconURL"],
      isActive: json["IsActive"] ?? true,
    );
  }
}
