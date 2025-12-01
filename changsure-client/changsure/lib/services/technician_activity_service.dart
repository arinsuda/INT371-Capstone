import 'package:dio/dio.dart';
import '../api/api_client.dart';
import 'package:changsure/models/technicians/technician_activity.dart';

class TechnicianWorkService {
  final ApiClient client;

  TechnicianWorkService(this.client);

  Future<TechnicianWorkListResponse> listWorks({
    int page = 1,
    int perPage = 10,
    int? serviceId,
    int? provinceId,
  }) async {
    final res = await client.dio.get(
      "/technician/works",
      queryParameters: {
        "page": page,
        "per_page": perPage,
        if (serviceId != null) "service_id": serviceId,
        if (provinceId != null) "province_id": provinceId,
      },
    );

    return TechnicianWorkListResponse.fromJson(res.data["data"]);
  }

  Future<TechnicianWork> getWork(int id) async {
    final res = await client.dio.get("/technician/works/$id");
    return TechnicianWork.fromJson(res.data["data"]);
  }

  Future<TechnicianWork> createWork(CreateTechnicianWorkDTO dto) async {
    final res = await client.dio.post("/technician/works", data: dto.toJson());

    return TechnicianWork.fromJson(res.data["data"]);
  }

  Future<TechnicianWork> updateWork(int id, UpdateTechnicianWorkDTO dto) async {
    final res = await client.dio.patch(
      "/technician/works/$id",
      data: dto.toJson(),
    );

    return TechnicianWork.fromJson(res.data["data"]);
  }

  Future<void> deleteWork(int id) async {
    await client.dio.delete("/technician/works/$id");
  }
}
