import '../api/api_client.dart';
import 'package:flutter/foundation.dart';
import '../models/provinces/province.dart';

class ProvinceRepository {
  final ApiClient client;
  ProvinceRepository(this.client);

  Future<List<ProvinceResponse>> getProvinces() async {
    final res = await client.dio.get("/provinces");

    debugPrint("GET /provinces -> status=${res.statusCode}");
    debugPrint("body = ${res.data}");

    if (res.statusCode != 200) {
      throw Exception("HTTP ${res.statusCode}");
    }

    final body = res.data;

    List<dynamic> rawList;

    if (body is Map<String, dynamic>) {
      if (body["success"] == false) {
        throw Exception(body["message"] ?? "Load provinces failed");
      }

      if (body["data"] is List) {
        rawList = body["data"];
      } else if (body["provinces"] is List) {
        rawList = body["provinces"];
      } else {
        throw Exception("Unexpected 'provinces' response structure");
      }
    } else if (body is List) {
      rawList = body;
    } else {
      throw Exception("Unexpected provinces response type");
    }

    final provinces = rawList
        .map((e) => ProvinceResponse.fromJson(e as Map<String, dynamic>))
        .toList();

    return provinces;
  }
}
