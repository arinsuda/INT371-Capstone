class Technician {
  final int id;
  final String firstname;
  final String lastname;
  final String bio;
  final String phone;
  final String email;
  final String avatarUrl;
  
  final double ratingAvg;
  final int ratingCount;
  final int totalJobs;

  final bool isAvailable;
  final bool isVerified;

  Technician({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.bio,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    required this.ratingAvg,
    required this.ratingCount,
    required this.totalJobs,
    required this.isAvailable,
    required this.isVerified,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      bio: json['bio'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      ratingAvg: (json['rating_avg'] ?? 0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      totalJobs: json['total_jobs'] ?? 0,
      isAvailable: json['is_available'] ?? false,
      isVerified: json['is_verified'] ?? false,
    );
  }
}
