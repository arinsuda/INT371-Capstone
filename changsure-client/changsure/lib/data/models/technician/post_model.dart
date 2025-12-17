class PostModel {
  final int id;
  final String title;
  final String content;
  final List<String> images;
  final String createdAt;
  final int serviceId;
  final String serviceName;
  final int serviceCategoryId;
  final String serviceCategoryName;
  final String provinceName;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    required this.images,
    required this.createdAt,
    required this.serviceId,
    required this.serviceName,
    required this.serviceCategoryId,
    required this.serviceCategoryName,
    required this.provinceName,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    List<String> imgList = [];
    if (json['images'] != null) {
      imgList = (json['images'] as List)
          .map((item) => (item['image_url'] ?? '').toString())
          .where((url) => url.isNotEmpty)
          .toList();
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
      images: imgList,
      createdAt: dateStr,
      serviceId: json['service_id'] ?? 0,
      serviceName: json['service_name'] ?? '',
      provinceName: json['province_name'] ?? '',

      serviceCategoryId:
          json['service_category_id'] ?? json['category_id'] ?? 0,
      serviceCategoryName:
          json['service_category_name'] ??
          json['category_name'] ??
          json['service_name'] ??
          'งานทั่วไป',
    );
  }
}
