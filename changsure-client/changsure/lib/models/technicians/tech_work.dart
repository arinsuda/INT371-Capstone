
class TechnicianWork {
  final int id;
  final int technicianId;

  final String title;
  final String? description;

  final int? serviceId;
  final String? serviceName;

  final int? provinceId;
  final String? provinceName;

  final String? workDate; // Keep as string from BE

  final bool isPublished;
  final int createdAt; // BE sends UNIX timestamp

  final List<TechnicianWorkImage> images;

  TechnicianWork({
    required this.id,
    required this.technicianId,
    required this.title,
    this.description,
    this.serviceId,
    this.serviceName,
    this.provinceId,
    this.provinceName,
    this.workDate,
    required this.isPublished,
    required this.createdAt,
    required this.images,
  });

  factory TechnicianWork.fromJson(Map<String, dynamic> json) {
    return TechnicianWork(
      id: _jsonInt(json["id"]),
      technicianId: _jsonInt(json["technician_id"]),

      title: json["title"] ?? "",
      description: json["description"],

      serviceId: (json["service_id"] as num?)?.toInt(),
      serviceName: json["service_name"],

      provinceId: (json["province_id"] as num?)?.toInt(),
      provinceName: json["province_name"],

      workDate: json["work_date"],

      isPublished: json["is_published"] ?? true,
      createdAt: _jsonInt(json["created_at"]),

      images: (json["images"] as List? ?? [])
          .map((e) => TechnicianWorkImage.fromJson(e))
          .toList(),
    );
  }

  static int _jsonInt(dynamic v) => (v as num?)?.toInt() ?? 0;
}

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
      id: _jsonInt(json["id"]),
      imageUrl: json["image_url"] ?? "",
      order: _jsonInt(json["order"]),
    );
  }

  static int _jsonInt(dynamic v) => (v as num?)?.toInt() ?? 0;
}
