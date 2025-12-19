class ProvinceModel {
  final int id;
  final String nameTh;

  ProvinceModel({required this.id, required this.nameTh});

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(id: json['id'], nameTh: json['name_th']);
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
  final String? serDescription;
  final List<String> serDetails;
  final List<String> imageUrls;
  final List<String> workingDuration;
  final List<String> additionalTerms;
  final ServicePrice defaultPrice;

  ServiceModel({
    required this.id,
    required this.serName,
    required this.categoryId,
    this.serDescription,
    this.serDetails = const [],
    this.imageUrls = const [],
    this.workingDuration = const [],
    this.additionalTerms = const [],
    required this.defaultPrice,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      serName: json['ser_name'] ?? '',
      categoryId: json['category_id'] ?? 0,
      serDescription: json['ser_description'],
      serDetails: List<String>.from(json['ser_details'] ?? []),
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      workingDuration: List<String>.from(json['working_duration'] ?? []),
      additionalTerms: List<String>.from(json['additional_terms'] ?? []),
      defaultPrice: ServicePrice.fromJson(json['default_price'] ?? {}),
    );
  }
}

class ServicePrice {
  final int? min;
  final int? max;
  final int? value;
  final String? type;

  ServicePrice({this.min, this.max, this.value, this.type});

  factory ServicePrice.fromJson(Map<String, dynamic> json) {
    return ServicePrice(
      min: json['min'],
      max: json['max'],
      value: json['value'],
      type: json['type'],
    );
  }
}
