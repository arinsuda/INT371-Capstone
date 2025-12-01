int safeInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double safeDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

String safeString(dynamic v) {
  if (v == null) return "";
  return v.toString();
}

class CustomerProfile {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String phone;
  final String avatarUrl;
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
      id: safeInt(json['id']),
      firstname: safeString(json['firstname']),
      lastname: safeString(json['lastname']),
      email: safeString(json['email']),
      phone: safeString(json['phone']),
      avatarUrl: safeString(json['avatar_url']),
      createdAt: safeString(json["created_at"]),
      updatedAt: safeString(json["updated_at"]),
    );
  }
}
