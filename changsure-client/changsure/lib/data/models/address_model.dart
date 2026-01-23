class AddressModel {
  final int id;
  final String? label;
  final String phoneNumber;

  final String houseNumber;
  final String? village;
  final String? moo;
  final String? soi;
  final String? road;

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

  String get displayName =>
      (label != null && label!.isNotEmpty) ? label! : houseNumber;

  AddressModel({
    required this.id,
    this.label,
    required this.phoneNumber,
    required this.houseNumber,
    this.village,
    this.moo,
    this.soi,
    this.road,
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

  String get combinedAddressInfo {
    List<String> parts = [houseNumber];
    if (village != null && village!.isNotEmpty) parts.add('$village');
    if (moo != null && moo!.isNotEmpty) parts.add('หมู่ $moo');
    if (soi != null && soi!.isNotEmpty) parts.add('ซ.$soi');
    if (road != null && road!.isNotEmpty) parts.add('ถ.$road');

    return parts.join(' ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] ?? 0,

      label: json['label'],
      phoneNumber: (json['phone_number'] ?? '').toString(),

      houseNumber: json['house_number'] ?? '',
      village: json['village'],
      moo: json['moo'],
      soi: json['soi'],
      road: json['road'],

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

      'house_number': houseNumber,
      'village': village,
      'moo': moo,
      'soi': soi,
      'road': road,

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
}
