class TechnicianAddress {
  final int id;
  final int technicianId;
  final String addressLine;
  final String subDistrict;
  final String district;
  final String province;
  final String postalCode;
  final double latitude;
  final double longitude;
  final bool isPrimary;
  final DateTime createdAt;
  final DateTime updatedAt;

  TechnicianAddress({
    required this.id,
    required this.technicianId,
    required this.addressLine,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TechnicianAddress.fromJson(Map<String, dynamic> json) {
    return TechnicianAddress(
      id: json["id"],
      technicianId: json["technician_id"],
      addressLine: json["address_line"],
      subDistrict: json["sub_district"],
      district: json["district"],
      province: json["province"],
      postalCode: json["postal_code"],
      latitude: (json["latitude"] as num).toDouble(),
      longitude: (json["longitude"] as num).toDouble(),
      isPrimary: json["is_primary"],
      createdAt: DateTime.parse(json["created_at"]),
      updatedAt: DateTime.parse(json["updated_at"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "address_line": addressLine,
    "sub_district": subDistrict,
    "district": district,
    "province": province,
    "postal_code": postalCode,
    "latitude": latitude,
    "longitude": longitude,
    "is_primary": isPrimary,
  };
}
