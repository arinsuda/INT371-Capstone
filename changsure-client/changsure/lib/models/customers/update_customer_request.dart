class CreateCustomerRequest {
  final String firstname;
  final String lastname;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  CreateCustomerRequest({
    required this.firstname,
    required this.lastname,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    "firstname": firstname,
    "lastname": lastname,
    if (email != null) "email": email,
    if (phone != null) "phone": phone,
    if (avatarUrl != null) "avatar_url": avatarUrl,
  };
}

class UpdateCustomerRequest {
  final String? firstname;
  final String? lastname;
  final String? email;
  final String? phone;
  final String? avatarUrl;

  UpdateCustomerRequest({
    this.firstname,
    this.lastname,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  Map<String, dynamic> toJson() => {
    if (firstname != null) "firstname": firstname,
    if (lastname != null) "lastname": lastname,
    if (email != null) "email": email,
    if (phone != null) "phone": phone,
    if (avatarUrl != null) "avatar_url": avatarUrl,
  };
}

class CustomerResponse {
  final int id;
  final String firstname;
  final String lastname;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String createdAt;
  final String updatedAt;
  final List<CustomerAddressResponse>? addresses;

  CustomerResponse({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.email,
    this.phone,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.addresses,
  });

  factory CustomerResponse.fromJson(Map<String, dynamic> json) {
    return CustomerResponse(
      id: (json["id"] as num).toInt(),
      firstname: json["firstname"] ?? "",
      lastname: json["lastname"] ?? "",
      email: json["email"],
      phone: json["phone"],
      avatarUrl: json["avatar_url"],
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
      addresses: json["addresses"] != null
          ? (json["addresses"] as List)
                .map(
                  (e) => CustomerAddressResponse.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : null,
    );
  }
}

class ProvinceResponse {
  final int id;
  final String? nameTh;

  ProvinceResponse({required this.id, this.nameTh});

  factory ProvinceResponse.fromJson(Map<String, dynamic> json) {
    return ProvinceResponse(
      id: (json["id"] as num).toInt(),
      nameTh: json["name_th"],
    );
  }
}

class CustomerAddressResponse {
  final int id;
  final String? houseNumber;
  final String? village;
  final String? moo;
  final String? soi;
  final String? road;
  final String? subdistrict;
  final String? district;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String updatedAt;
  final ProvinceResponse? province;

  CustomerAddressResponse({
    required this.id,
    this.houseNumber,
    this.village,
    this.moo,
    this.soi,
    this.road,
    this.subdistrict,
    this.district,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    this.province,
  });

  factory CustomerAddressResponse.fromJson(Map<String, dynamic> json) {
    return CustomerAddressResponse(
      id: (json["id"] as num).toInt(),
      houseNumber: json["house_number"],
      village: json["village"],
      moo: json["moo"],
      soi: json["soi"],
      road: json["road"],
      subdistrict: json["subdistrict"],
      district: json["district"],
      postalCode: json["postal_code"],
      country: json["country"],
      latitude: (json["latitude"] as num?)?.toDouble(),
      longitude: (json["longitude"] as num?)?.toDouble(),
      createdAt: json["created_at"] ?? "",
      updatedAt: json["updated_at"] ?? "",
      province: json["province"] != null
          ? ProvinceResponse.fromJson(json["province"] as Map<String, dynamic>)
          : null,
    );
  }
}
