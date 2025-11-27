import '../api/api_client.dart';
import 'package:flutter/foundation.dart';

class ProvinceRepository {
  final ApiClient client;
  ProvinceRepository(this.client);

  Future<List<String>> getProvinces() async {
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
        rawList = body["data"] as List;
      } else if (body["provinces"] is List) {
        rawList = body["provinces"] as List;
      } else {
        throw Exception("Unexpected provinces format");
      }
    } else if (body is List) {
      rawList = body;
    } else {
      throw Exception("Unexpected provinces response type");
    }

    final names = rawList
        .map((e) {
          if (e is String) {
            return e;
          } else if (e is Map<String, dynamic>) {
            return (e["name_th"] ?? e["nameTH"] ?? e["name"] ?? "").toString();
          } else {
            return e.toString();
          }
        })
        .where((name) => name.isNotEmpty)
        .toList();

    names.sort();
    return names;
  }
}
