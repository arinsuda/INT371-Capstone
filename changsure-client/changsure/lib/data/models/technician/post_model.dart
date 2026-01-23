class PostModel {
  final int id;
  final String title;
  final String content;
  final List<String> images;
  final List<int> imageIds;
  final String createdAt;
  final int serviceId;
  final String serviceName;
  final int categoryId;
  final String categoryName;
  final String provinceName;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.images,
    required this.imageIds,
    required this.createdAt,
    required this.serviceId,
    required this.serviceName,
    required this.categoryId,
    required this.categoryName,
    required this.provinceName,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    List<String> imgUrls = [];
    List<int> imgIds = [];

    if (json['images'] != null) {
      for (var item in json['images']) {
        imgUrls.add(item['image_url'] ?? '');
        imgIds.add(item['id'] ?? 0);
      }
    }

    String dateStr = '';
    if (json['created_at'] != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(
        (json['created_at'] as int) * 1000,
      );
      dateStr = "${date.day}/${date.month}/${date.year}";
    }

    return PostModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      content: json['description'] ?? '',
      images: imgUrls,
      imageIds: imgIds,
      createdAt: dateStr,
      serviceId: json['service_id'] ?? 0,
      serviceName: json['service_name'] ?? '',

      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? 'งานทั่วไป',
      provinceName: json['province_name'] ?? '',
    );
  }
}
