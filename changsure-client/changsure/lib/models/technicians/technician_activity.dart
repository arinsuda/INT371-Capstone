import 'dart:convert';

class TechnicianWorkImage {
  final int id;
  final String imageUrl;
  final int order;

  TechnicianWorkImage({
    required this.id,
    required this.imageUrl,
    required this.order,
  });

  factory TechnicianWorkImage.fromJson(Map<String, dynamic> json) {
    return TechnicianWorkImage(
      id: json["id"] ?? 0,
      imageUrl: json["image_url"] ?? "",
      order: json["order"] ?? 0,
    );
  }
}

class TechnicianWork {
  final int id;
  final int technicianId;

  final String title;
  final String? description;

  final int? serviceId;
  final String? serviceName;
  final int? provinceId;
  final String? provinceName;

  final DateTime? workDate;
  final bool isPublished;
  final int createdAt;

  final List<TechnicianWorkImage> images;

  TechnicianWork({
    required this.id,
    required this.technicianId,
    required this.title,
    required this.description,
    required this.serviceId,
    required this.serviceName,
    required this.provinceId,
    required this.provinceName,
    required this.workDate,
    required this.images,
    required this.isPublished,
    required this.createdAt,
  });

  factory TechnicianWork.fromJson(Map<String, dynamic> json) {
    return TechnicianWork(
      id: json["id"],
      technicianId: json["technician_id"],
      title: json["title"],
      description: json["description"],
      serviceId: json["service_id"],
      serviceName: json["service_name"],
      provinceId: json["province_id"],
      provinceName: json["province_name"],
      workDate: json["work_date"] != null
          ? DateTime.tryParse(json["work_date"])
          : null,
      images: (json["images"] as List<dynamic>? ?? [])
          .map((e) => TechnicianWorkImage.fromJson(e))
          .toList(),
      isPublished: json["is_published"] ?? true,
      createdAt: json["created_at"] ?? 0,
    );
  }
}

class CreateTechnicianWorkDTO {
  String title;
  String? description;
  int? serviceId;
  int? provinceId;
  DateTime? workDate;
  List<String> imageUrls;

  CreateTechnicianWorkDTO({
    required this.title,
    this.description,
    this.serviceId,
    this.provinceId,
    this.workDate,
    required this.imageUrls,
  });

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
    "service_id": serviceId,
    "province_id": provinceId,
    "work_date": workDate?.toIso8601String(),
    "image_urls": imageUrls,
  };
}

class UpdateTechnicianWorkDTO {
  String? title;
  String? description;
  int? serviceId;
  int? provinceId;
  DateTime? workDate;
  bool? isPublished;
  List<String>? imageUrls;

  UpdateTechnicianWorkDTO({
    this.title,
    this.description,
    this.serviceId,
    this.provinceId,
    this.workDate,
    this.isPublished,
    this.imageUrls,
  });

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
    "service_id": serviceId,
    "province_id": provinceId,
    "work_date": workDate?.toIso8601String(),
    "is_published": isPublished,
    "image_urls": imageUrls,
  };
}

class TechnicianWorkListResponse {
  final List<TechnicianWork> items;
  final int page;
  final int perPage;
  final int total;

  TechnicianWorkListResponse({
    required this.items,
    required this.page,
    required this.perPage,
    required this.total,
  });

  factory TechnicianWorkListResponse.fromJson(Map<String, dynamic> json) {
    return TechnicianWorkListResponse(
      items: (json["items"] as List<dynamic>? ?? [])
          .map((e) => TechnicianWork.fromJson(e))
          .toList(),
      page: json["page"] ?? 1,
      perPage: json["per_page"] ?? 10,
      total: json["total"] ?? 0,
    );
  }
}
