class TechnicianProfileRequest {
  final String firstname;
  final String lastname;
  final String? bio;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final List<int>? provinceIds;

  TechnicianProfileRequest({
    required this.firstname,
    required this.lastname,
    this.bio,
    this.phone,
    this.email,
    this.avatarUrl,
    this.provinceIds,
  });

  Map<String, dynamic> toJson() => {
    "firstname": firstname,
    "lastname": lastname,
    if (bio != null) "bio": bio,
    if (phone != null) "phone": phone,
    if (email != null) "email": email,
    if (avatarUrl != null) "avatar_url": avatarUrl,
    if (provinceIds != null) "province_ids": provinceIds,
  };
}

class TechnicianProvincesPatchRequest {
  final List<int> provinceIds;
  TechnicianProvincesPatchRequest({required this.provinceIds});

  Map<String, dynamic> toJson() => {"province_ids": provinceIds};
}

class AddTechServiceRequest {
  final int serviceId;
  final String pricingType;
  final double? priceFixed;
  final double? priceMin;
  final double? priceMax;

  AddTechServiceRequest({
    required this.serviceId,
    required this.pricingType,
    this.priceFixed,
    this.priceMin,
    this.priceMax,
  });

  Map<String, dynamic> toJson() => {
    "service_id": serviceId,
    "pricing_type": pricingType,
    if (priceFixed != null) "price_fixed": priceFixed,
    if (priceMin != null) "price_min": priceMin,
    if (priceMax != null) "price_max": priceMax,
  };
}

class RemoveTechServiceRequest {
  final int provinceId;
  final int serviceId;

  RemoveTechServiceRequest({required this.provinceId, required this.serviceId});

  Map<String, dynamic> toJson() => {
    "province_id": provinceId,
    "service_id": serviceId,
  };
}
