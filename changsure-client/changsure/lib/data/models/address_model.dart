class AddressModel {
  final int id;
  final String houseNumber;
  final String? village;
  final String? moo;
  final String? soi;
  final String? road;
  final String subDistrict;
  final String district;
  final String province;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;

  AddressModel({
    required this.id,
    required this.houseNumber,
    this.village,
    this.moo,
    this.soi,
    this.road,
    required this.subDistrict,
    required this.district,
    required this.province,
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
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
      houseNumber: json['house_number'] ?? '',
      village: json['village'],
      moo: json['moo'],
      soi: json['soi'],
      road: json['road'],
      subDistrict: json['sub_district'] ?? '',
      district: json['district'] ?? '',
      province: json['province'] ?? '',
      postalCode: json['postal_code'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPrimary: json['is_primary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'house_number': houseNumber,
      'village': village,
      'moo': moo,
      'soi': soi,
      'road': road,
      'sub_district': subDistrict,
      'district': district,
      'province': province,
      'postal_code': postalCode,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': isPrimary,
    };
  }
}
