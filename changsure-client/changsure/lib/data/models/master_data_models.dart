class ProvinceModel {
  final int id;
  final String nameTh;

  ProvinceModel({required this.id, required this.nameTh});

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: json['id'],
      nameTh: json['name_th'],
    );
  }
}

class ServiceCategoryModel {
  final int id;
  final String catName;
  final List<ServiceModel> services;
  ServiceCategoryModel({
    required this.id,
    required this.catName,
    this.services = const [],
  });

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryModel(
      id: json['id'],
      catName: json['cat_name'],
      services: [],
    );
  }

  ServiceCategoryModel copyWith({List<ServiceModel>? services}) {
    return ServiceCategoryModel(
      id: id,
      catName: catName,
      services: services ?? this.services,
    );
  }
}

class ServiceModel {
  final int id;
  final String serName;
  final int categoryId;
  final int? minPrice;
  final int? maxPrice;
  final String? priceType;

  ServiceModel({
    required this.id,
    required this.serName,
    required this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.priceType,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final defaultPrice = json['default_price'] ?? {};

    return ServiceModel(
      id: json['id'],
      serName: json['ser_name'],
      categoryId: json['category_id'],
      minPrice: defaultPrice['min'],
      maxPrice:
          defaultPrice['max'] ??
          defaultPrice['value'],
      priceType: defaultPrice['type'],
    );
  }
}
