class CustomerProfile {
  final int id;
  final String firstname;
  final String lastname;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String createdAt;
  final String updatedAt;

  CustomerProfile({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final f = firstname.trim();
    final l = lastname.trim();
    final name = ('$f $l').trim();
    return name.isEmpty ? '-' : name;
  }

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
    );
  }
}
