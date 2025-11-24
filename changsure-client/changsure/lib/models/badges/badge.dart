class BadgeResponse {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;

  BadgeResponse({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
  });

  factory BadgeResponse.fromJson(Map<String, dynamic> json) {
    return BadgeResponse(
      id: (json["id"] as num).toInt(),
      name: json["name"] ?? "",
      description: json["description"],
      iconUrl: json["icon_url"],
    );
  }
}