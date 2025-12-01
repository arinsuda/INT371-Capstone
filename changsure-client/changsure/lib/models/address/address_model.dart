class AddressModel {
  final int id;

  final String? houseNumber;
  final String? village;
  final String? moo;
  final String? soi;
  final String? road;

  final String? subDistrict;
  final String? district;
  final String? province;

  final String? postalCode;
  final String? country;

  final int? provinceId;

  final double? latitude;
  final double? longitude;

  final bool isPrimary;

  AddressModel({
    required this.id,
    this.houseNumber,
    this.village,
    this.moo,
    this.soi,
    this.road,
    this.subDistrict,
    this.district,
    this.province,
    this.postalCode,
    this.country,
    this.provinceId,
    this.latitude,
    this.longitude,
    required this.isPrimary,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json["id"],
      houseNumber: json["house_number"],
      village: json["village"],
      moo: json["moo"],
      soi: json["soi"],
      road: json["road"],
      subDistrict: json["sub_district"],
      district: json["district"],
      province: json["province"],
      postalCode: json["postal_code"],
      country: json["country"],
      provinceId: json["province_id"],
      latitude: (json["latitude"] as num?)?.toDouble(),
      longitude: (json["longitude"] as num?)?.toDouble(),
      isPrimary: json["is_primary"] ?? false,
    );
  }
}
