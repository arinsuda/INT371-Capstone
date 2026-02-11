class AddressModel {
  final int id;
  final String? label;
  final String phoneNumber;

  final String addressLine;
  final String postalCode;

  final double? latitude;
  final double? longitude;

  final bool isPrimary;

  final String subDistrict;
  final String district;
  final String province;
  final int? subDistrictId;
  final int? districtId;
  final int? provinceId;

  // Cache computed property
  String? _cachedDisplayName;

  String get displayName {
    _cachedDisplayName ??= (label != null && label!.isNotEmpty)
        ? label!
        : addressLine;
    return _cachedDisplayName!;
  }

  AddressModel({
    required this.id,
    this.label,
    required this.phoneNumber,
    required this.addressLine,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    required this.subDistrict,
    required this.district,
    required this.province,
    this.subDistrictId,
    this.districtId,
    this.provinceId,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,
      label: json['label'],
      phoneNumber: (json['phone_number'] ?? '').toString(),
      addressLine: json['address_line'] ?? '',
      postalCode: json['postal_code'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPrimary: json['is_primary'] ?? false,
      subDistrict: json['sub_district_name'] ?? json['sub_district'] ?? '',
      district: json['district_name'] ?? json['district'] ?? '',
      province: json['province_name'] ?? json['province'] ?? '',
      subDistrictId: json['sub_district_id'],
      districtId: json['district_id'],
      provinceId: json['province_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'phone_number': phoneNumber,
      'address_line': addressLine,
      'sub_district': subDistrict,
      'district': district,
      'province': province,
      'sub_district_id': subDistrictId,
      'district_id': districtId,
      'province_id': provinceId,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': isPrimary,
    };
  }

  // Add copyWith for immutability
  AddressModel copyWith({
    int? id,
    String? label,
    String? phoneNumber,
    String? addressLine,
    String? postalCode,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    String? subDistrict,
    String? district,
    String? province,
    int? subDistrictId,
    int? districtId,
    int? provinceId,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine: addressLine ?? this.addressLine,
      postalCode: postalCode ?? this.postalCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      subDistrict: subDistrict ?? this.subDistrict,
      district: district ?? this.district,
      province: province ?? this.province,
      subDistrictId: subDistrictId ?? this.subDistrictId,
      districtId: districtId ?? this.districtId,
      provinceId: provinceId ?? this.provinceId,
    );
  }

  // Implement equality for better comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AddressModel &&
        other.id == id &&
        other.label == label &&
        other.phoneNumber == phoneNumber &&
        other.addressLine == addressLine &&
        other.postalCode == postalCode &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.isPrimary == isPrimary &&
        other.subDistrict == subDistrict &&
        other.district == district &&
        other.province == province &&
        other.subDistrictId == subDistrictId &&
        other.districtId == districtId &&
        other.provinceId == provinceId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      label,
      phoneNumber,
      addressLine,
      postalCode,
      latitude,
      longitude,
      isPrimary,
      subDistrict,
      district,
      province,
      subDistrictId,
      districtId,
      provinceId,
    );
  }
}
