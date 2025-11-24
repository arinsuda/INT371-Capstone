import '../services/service.dart';
import '../provinces/province.dart';

class TechnicianWork {
  final int id;
  final int technicianId;

  final String title;
  final String? description;

  final int? serviceId;
  final int? provinceId;
  final String? workDate;

  final bool isPublished;
  final String createdAt;
  final String updatedAt;

  final ServiceResponse? service;
  final ProvinceResponse? province;

  final List<TechnicianWorkImage> images;

  TechnicianWork({
    required this.id,
    required this.technicianId,
    required this.title,
    this.description,
    this.serviceId,
    this.provinceId,
    this.workDate,
    required this.isPublished,
    required this.createdAt,
    required this.updatedAt,
    this.service,
    this.province,
    required this.images,
  });

  factory TechnicianWork.fromJson(Map<String, dynamic> json) {
    return TechnicianWork(
      id: _jsonInt(json["id"]),
      technicianId: _jsonInt(json["technician_id"]),
      title: json["title"] ?? "",
      description: json["description"],
      serviceId: (json["service_id"] as num?)?.toInt(),
      provinceId: (json["province_id"] as num?)?.toInt(),
      workDate: json["work_date"],

      isPublished: json["is_published"] ?? true,
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",

      service: json["service"] != null
          ? ServiceResponse.fromJson(json["service"] as Map<String, dynamic>)
          : null,
      province: json["province"] != null
          ? ProvinceResponse.fromJson(json["province"] as Map<String, dynamic>)
          : null,

      images: (json["images"] as List? ?? [])
          .map((e) => TechnicianWorkImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _jsonInt(dynamic v) => (v as num?)?.toInt() ?? 0;
}

class TechnicianWorkImage {
  final int id;
  final int workId;
  final String imageUrl;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  TechnicianWorkImage({
    required this.id,
    required this.workId,
    required this.imageUrl,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TechnicianWorkImage.fromJson(Map<String, dynamic> json) {
    return TechnicianWorkImage(
      id: _jsonInt(json["id"]),
      workId: _jsonInt(json["work_id"]),
      imageUrl: json["image_url"] ?? "",
      sortOrder: _jsonInt(json["sort_order"]),
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
    );
  }

  static int _jsonInt(dynamic v) => (v as num?)?.toInt() ?? 0;
}
