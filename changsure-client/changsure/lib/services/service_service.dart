import 'package:dio/dio.dart';
import 'package:changsure/api/api_client.dart';
import 'package:changsure/models/services/service.dart';

class ServiceApi {
  final ApiClient client;

  ServiceApi(this.client);

  Future<List<ServiceModel>> listServices({
    String? search,
    int? categoryId,
    bool? isActive,
    int page = 1,
    int pageSize = 20,
    String sortBy = "created_at",
    String sortOrder = "desc",
  }) async {
    final res = await client.dio.get(
      "/services",
      queryParameters: {
        "search": search,
        "category_id": categoryId,
        "is_active": isActive,
        "page": page,
        "page_size": pageSize,
        "sort_by": sortBy,
        "sort_order": sortOrder,
      },
    );

    final data = res.data["data"] as List? ?? [];
    return data.map((e) => ServiceModel.fromJson(e)).toList();
  }

  Future<ServiceModel> getService(int id) async {
    final res = await client.dio.get("/services/$id");

    return ServiceModel.fromJson(res.data["data"]);
  }
}
