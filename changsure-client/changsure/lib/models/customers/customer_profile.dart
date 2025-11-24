class Profile {
  final int id;
  final String firstname;
  final String lastname;
  final String email;
  final String phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName {
    final f = firstname.trim();
    final l = lastname.trim();
    final name = ('$f $l').trim();
    return name.isEmpty ? '-' : name;
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
