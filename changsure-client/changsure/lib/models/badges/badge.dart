class BadgeResponse {
  final int id;
  final String name;
  final String description;
  final String iconUrl;
  final int level;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BadgeResponse({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.level,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory BadgeResponse.fromJson(Map<String, dynamic> json) {
    return BadgeResponse(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      level: json['level'] ?? 0,
      isActive: json['is_active'] ?? false,
      createdAt: (json['created_at'] is int)
          ? DateTime.fromMillisecondsSinceEpoch(json['created_at'] * 1000)
          : null,
      updatedAt: (json['updated_at'] is int)
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] * 1000)
          : null,
    );
  }
}
