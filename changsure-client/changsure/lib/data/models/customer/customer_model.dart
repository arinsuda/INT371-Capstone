// lib/data/models/customer_model.dart

class CustomerModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  // ข้อมูลที่อยู่ (Nested List)
  final List<CustomerAddress> addresses;

  CustomerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.avatarUrl,
    this.addresses = const [],
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

      addresses:
          (json['addresses'] as List<dynamic>?)
              ?.map((e) => CustomerAddress.fromJson(e))
              .toList() ??
          [],
    );
  }
}

// --- Sub-Class: ที่อยู่ลูกค้า ---
class CustomerAddress {
  final int id;
  final String houseNumber;
  final String subDistrict; // แขวง/ตำบล
  final String district; // เขต/อำเภอ
  final String province; // จังหวัด
  final String postalCode;
  final bool isPrimary;

  CustomerAddress({
    required this.id,
    required this.houseNumber,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postalCode,
    this.isPrimary = false,
  });

  // สร้าง String ที่อยู่เต็มรูปแบบ
  String get fullAddress =>
      '$houseNumber ต.$subDistrict อ.$district จ.$province $postalCode';

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] ?? 0,
      houseNumber: json['house_number'] ?? '',
      subDistrict: json['sub_district'] ?? '',
      district: json['district'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}
