class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final String? entityType;
  final int? entityId;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.entityType,
    this.entityId,
    this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      entityType: json['entity_type'],
      entityId: json['entity_id'],
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
