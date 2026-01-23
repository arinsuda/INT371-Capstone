import 'package:changsure/data/models/address_model.dart';

class CustomerModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  String get fullName => '$firstName $lastName';

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? 0,
      firstName: json['firstname'] ?? '',
      lastName: json['lastname'] ?? '',
      email: json['email'],
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
    );
  }

  /// 👇 สำหรับ PATCH / PUT profile
  Map<String, dynamic> toJson() {
    return {
      'firstname': firstName,
      'lastname': lastName,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
    };
  }

  CustomerModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) {
    return CustomerModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

}


