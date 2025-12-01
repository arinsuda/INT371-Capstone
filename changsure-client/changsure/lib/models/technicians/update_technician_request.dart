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

class TechnicianProfileResponse {
  final int id;
  final String firstname;
  final String lastname;
  final String? bio;
  final String? phone;
  final String? email;
  final String? avatarUrl;

  final double? ratingAvg;
  final int ratingCount;
  final int totalJobs;
  final bool isAvailable;
  final bool isVerified;

  final List<ProvinceResponse> provinces;
  final List<TechServiceResponse> services;
  final List<TechServiceSummary> serviceSummary;
  final List<BadgeResponse> badges;

  TechnicianProfileResponse({
    required this.id,
    required this.firstname,
    required this.lastname,
    this.bio,
    this.phone,
    this.email,
    this.avatarUrl,
    this.ratingAvg,
    required this.ratingCount,
    required this.totalJobs,
    required this.isAvailable,
    required this.isVerified,
    required this.provinces,
    required this.services,
    required this.serviceSummary,
    required this.badges,
  });

  factory TechnicianProfileResponse.fromJson(Map<String, dynamic> json) {
    return TechnicianProfileResponse(
      id: (json["id"] as num).toInt(),
      firstname: json["firstname"] ?? "",
      lastname: json["lastname"] ?? "",
      bio: json["bio"],
      phone: json["phone"],
      email: json["email"],
      avatarUrl: json["avatar_url"],
      ratingAvg: (json["rating_avg"] as num?)?.toDouble(),
      ratingCount: (json["rating_count"] as num).toInt(),
      totalJobs: (json["total_jobs"] as num).toInt(),
      isAvailable: json["is_available"] ?? false,
      isVerified: json["is_verified"] ?? false,
      provinces: (json["provinces"] as List)
          .map((e) => ProvinceResponse.fromJson(e))
          .toList(),
      services: (json["services"] as List)
          .map((e) => TechServiceResponse.fromJson(e))
          .toList(),
      serviceSummary: (json["service_summary"] as List)
          .map((e) => TechServiceSummary.fromJson(e))
          .toList(),
      badges: (json["badges"] as List)
          .map((e) => BadgeResponse.fromJson(e))
          .toList(),
    );
  }
}

class TechServiceResponse {
  final int serviceId;
  final String serviceName;
  final int? categoryId;
  final String? categoryName;
  final String pricingType;
  final double? priceFixed;
  final double? priceMin;
  final double? priceMax;

  TechServiceResponse({
    required this.serviceId,
    required this.serviceName,
    this.categoryId,
    this.categoryName,
    required this.pricingType,
    this.priceFixed,
    this.priceMin,
    this.priceMax,
  });

  factory TechServiceResponse.fromJson(Map<String, dynamic> json) {
    return TechServiceResponse(
      serviceId: (json["service_id"] as num).toInt(),
      serviceName: json["service_name"] ?? "",
      categoryId: (json["category_id"] as num?)?.toInt(),
      categoryName: json["category_name"],
      pricingType: json["pricing_type"] ?? "",
      priceFixed: (json["price_fixed"] as num?)?.toDouble(),
      priceMin: (json["price_min"] as num?)?.toDouble(),
      priceMax: (json["price_max"] as num?)?.toDouble(),
    );
  }
}

class TechServiceSummary {
  final int serviceId;
  final String serviceName;

  TechServiceSummary({required this.serviceId, required this.serviceName});

  factory TechServiceSummary.fromJson(Map<String, dynamic> json) {
    return TechServiceSummary(
      serviceId: (json["service_id"] as num).toInt(),
      serviceName: json["service_name"] ?? "",
    );
  }
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

class BadgeResponse {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;

  BadgeResponse({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
  });

  factory BadgeResponse.fromJson(Map<String, dynamic> json) {
    return BadgeResponse(
      id: (json["id"] as num).toInt(),
      name: json["name"] ?? "",
      description: json["description"],
      iconUrl: json["icon_url"],
    );
  }
}
