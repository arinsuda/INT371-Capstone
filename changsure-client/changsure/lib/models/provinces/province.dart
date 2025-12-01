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