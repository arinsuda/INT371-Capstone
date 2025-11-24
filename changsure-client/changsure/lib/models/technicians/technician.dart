class Technician {
  final int id;
  final String firstname;
  final String lastname;
  final String? bio;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  final double? ratingAvg;
  final int ratingCount;
  final int totalJobs;
  final bool isAvailable;
  final bool isVerified;

  final String createdAt;
  final String updatedAt;

  Technician({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.bio,
    this.phone,
    this.email,
    this.avatarUrl,
    this.ratingAvg,
    required this.ratingCount,
    required this.totalJobs,
    required this.isAvailable,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => "$firstname $lastname";

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: _jsonInt(json["id"]),
      firstname: json["firstname"] ?? "",
      lastname: json["lastname"] ?? "",
      bio: json["bio"],
      phone: json["phone"],
      email: json["email"],
      avatarUrl: json["avatar_url"],
      ratingAvg: _jsonDouble(json["rating_avg"]),
      ratingCount: _jsonInt(json["rating_count"]),
      totalJobs: _jsonInt(json["total_jobs"]),
      isAvailable: json["is_available"] ?? false,
      isVerified: json["is_verified"] ?? false,
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
    );
  }

  static int _jsonInt(dynamic v) => (v as num?)?.toInt() ?? 0;
  static double? _jsonDouble(dynamic v) => (v as num?)?.toDouble();
}
