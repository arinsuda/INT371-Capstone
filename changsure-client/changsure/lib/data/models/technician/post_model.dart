class PostModel {
  final int id;
  final int technicianId;
  final String title;
  final String? description;
  final int? serviceId;
  final String? serviceName;
  final int? categoryId;
  final String? categoryName;
  final int? provinceId;
  final String? provinceName;
  final List<PostImage> images;
  final bool? isPublished;
  final int createdAt;

  PostModel({
    required this.id,
    required this.technicianId,
    required this.title,
    this.description,
    this.serviceId,
    this.serviceName,
    this.categoryId,
    this.categoryName,
    this.provinceId,
    this.provinceName,
    required this.images,
    this.isPublished,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: (json['id'] ?? 0) as int,
      technicianId: (json['technician_id'] ?? 0) as int,
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      serviceId: json['service_id'] as int?,
      serviceName: json['service_name'] as String?,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      provinceId: json['province_id'] as int?,
      provinceName: json['province_name'] as String?,
      images:
          (json['images'] as List?)
              ?.map((e) => PostImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isPublished: json['is_published'] as bool?,
      createdAt: (json['created_at'] ?? 0) as int,
    );
  }

  DateTime get createdDate =>
      DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);

  String get formattedDate {
    final date = createdDate;
    return "${date.day}/${date.month}/${date.year}";
  }
}

class PostImage {
  final int id;
  final String imageUrl;
  final int order;

  PostImage({required this.id, required this.imageUrl, required this.order});

  factory PostImage.fromJson(Map<String, dynamic> json) {
    return PostImage(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      order: json['order'] ?? 0,
    );
  }
}
