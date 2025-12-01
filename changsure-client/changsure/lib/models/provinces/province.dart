class ProvinceResponse {
  final int id;
  final String? nameTh;

  ProvinceResponse({required this.id, this.nameTh});

  factory ProvinceResponse.fromJson(Map<String, dynamic> json) {
    final rawId = json["id"];

    return ProvinceResponse(
      id: (rawId is int)
          ? rawId
          : (rawId is num)
          ? rawId.toInt()
          : 0,
      nameTh: json["name_th"] as String?,
    );
  }
}
