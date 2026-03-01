class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;

  final String? entityType;

  final int? entityId;
  final Map<String, dynamic>? data;
  final bool isRead;

  final DateTime? readAt;
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
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final raw = DateTime.parse(json['created_at'] as String);

    final entityType = json['entity_type'] as String?;
    final entityTypeOrNull = (entityType != null && entityType.isNotEmpty)
        ? entityType
        : null;

    final entityId = json['entity_id'];
    final entityIdOrNull = (entityId != null && entityId != 0)
        ? (entityId as num).toInt()
        : null;

    DateTime? readAt;
    if (json['read_at'] != null) {
      try {
        final rawReadAt = DateTime.parse(json['read_at'] as String);
        readAt = rawReadAt.isUtc ? rawReadAt.toLocal() : rawReadAt;
      } catch (_) {}
    }

    return NotificationModel(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      entityType: entityTypeOrNull,
      entityId: entityIdOrNull,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'] as Map)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      readAt: readAt,
      createdAt: raw.isUtc ? raw.toLocal() : raw,
    );
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      entityType: entityType,
      entityId: entityId,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class NotificationListResult {
  final List<NotificationModel> items;
  final int? nextCursor;
  final bool hasMore;

  NotificationListResult({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final itemsList = (data['items'] as List? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final nextCursorRaw = data['next_cursor'];
    final nextCursor = nextCursorRaw != null
        ? (nextCursorRaw as num).toInt()
        : null;

    return NotificationListResult(
      items: itemsList,
      nextCursor: nextCursor,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }
}
