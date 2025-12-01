import 'package:dio/dio.dart';
import 'package:changsure/api/api_client.dart';
import 'package:changsure/models/service_categories/service_category.dart';

class ServiceCategoryService {
  final ApiClient client;

  ServiceCategoryService(this.client);

  Future<List<ServiceCategoryModel>> fetchCategories() async {
    final res = await client.dio.get("/service-categories");

    final data = res.data["data"] as List? ?? [];
    return data.map((e) => ServiceCategoryModel.fromJson(e)).toList();
  }

  Future<ServiceCategoryModel> getCategory(int id) async {
    final res = await client.dio.get("/service-categories/$id");

    return ServiceCategoryModel.fromJson(res.data["data"]);
  }
}
